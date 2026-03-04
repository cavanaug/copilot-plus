---
phase: quick-3
plan: 3
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus
  - tests/copilot.bats
autonomous: true
requirements: [QUICK-3]

must_haves:
  truths:
    - "Running `copilot-plus +test <args>` prints the full copilot command (config flags + user args) to stdout without executing copilot"
    - "The +test option is stripped from the args before printing the command"
    - "Running without +test behaves exactly as before (exec copilot)"
    - "All existing bats tests continue to pass"
  artifacts:
    - path: "copilot-plus"
      provides: "+test flag handling before exec"
      contains: "+test"
    - path: "tests/copilot.bats"
      provides: "Tests for +test behavior"
      contains: "DRY-RUN"
  key_links:
    - from: "copilot-plus"
      to: "stdout"
      via: "echo/printf of full command when +test flag detected"
      pattern: "\\+test"
---

<objective>
Add a `+test` (dry-run) option to `copilot-plus` that prints the full `copilot` command that would be executed — including all config-injected flags and user-supplied args — without actually calling it.

Purpose: Lets users inspect exactly what `copilot-plus` would pass to `copilot` before running for real.
Output: Modified `copilot-plus` + new bats tests covering dry-run behavior.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode.gsd/get-shit-done/templates/summary.md
</execution_context>

<context>
@copilot-plus
@tests/copilot.bats
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add +test dry-run support to copilot-plus and tests</name>
  <files>copilot-plus, tests/copilot.bats</files>
  <behavior>
    - DRY-RUN-01: `copilot-plus +test myarg` → prints `copilot <config-flags> myarg` to stdout, exits 0, does NOT exec copilot (stub_args file absent)
    - DRY-RUN-02: `+test` anywhere in positional args is detected and stripped; remaining args are passed to the printed command
    - DRY-RUN-03: `copilot-plus +test` (no other args, no config) → prints `copilot` to stdout
    - DRY-RUN-04: `copilot-plus +test` with active config → prints `copilot <config-flags>` including all expanded flags
    - DRY-RUN-05: Without `+test`, existing behavior unchanged (exec copilot)
  </behavior>
  <action>
**Tests first (RED):**

Add the following tests to `tests/copilot.bats` (append after the last test):

```
# ============================================================
# DRY-RUN-01: +test → prints command to stdout, does NOT exec copilot
# ============================================================

@test "DRY-RUN-01: +test with no config → prints 'copilot' + user args, stub not called" {
  run_wrapper +test myarg
  [ "$status" -eq 0 ]
  [[ "$output" == "copilot myarg" ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-02: +test with config flags → flags appear in printed command
# ============================================================

@test "DRY-RUN-02: +test with config → prints full command with config flags + user args" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +test myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"copilot"* ]]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [[ "$output" == *"myarg"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-03: +test with no args and no config → prints just 'copilot'
# ============================================================

@test "DRY-RUN-03: +test only, no config, no user args → prints 'copilot'" {
  run_wrapper +test
  [ "$status" -eq 0 ]
  [[ "$output" == "copilot" ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-04: +test does not appear in printed command output
# ============================================================

@test "DRY-RUN-04: +test itself does not appear in the printed command" {
  run_wrapper +test myarg
  [ "$status" -eq 0 ]
  [[ "$output" != *"+test"* ]]
}

# ============================================================
# DRY-RUN-05: Without +test, existing exec behavior unchanged
# ============================================================

@test "DRY-RUN-05: without +test → normal exec, stub called as before" {
  write_config '{"--yolo":true}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
}
```

Verify tests FAIL (RED): `bats tests/copilot.bats --filter DRY-RUN`

**Implementation (GREEN):**

In `copilot-plus`, just before the final `exec` line (line 130), add `+test` detection:

1. After the `export COPILOT_ARGS` line (after line 128), add logic to detect and strip `+test` from the user's `$@` arguments:
   - Scan `$@` for `+test`; if found, set `dry_run=1` and rebuild remaining args without it
   - If `dry_run=1`: print the full command using `printf '%s ' copilot "${config_flags[@]+"${config_flags[@]}"}" "${remaining_args[@]}"` (trimmed), then `exit 0`
   - Otherwise: proceed to `exec copilot ...` as before

Concrete implementation to insert between lines 128 and 130:

```bash
# Check for +test dry-run flag anywhere in user args
dry_run=0
user_args=()
for arg in "$@"; do
  if [[ "$arg" == "+test" ]]; then
    dry_run=1
  else
    user_args+=("$arg")
  fi
done

if [[ "$dry_run" -eq 1 ]]; then
  cmd=(copilot "${config_flags[@]+"${config_flags[@]}"}" "${user_args[@]+"${user_args[@]}"}")
  printf '%s' "${cmd[0]}"
  for part in "${cmd[@]:1}"; do
    printf ' %s' "$part"
  done
  printf '\n'
  exit 0
fi
```

Then update the final `exec` line to use `"${user_args[@]}"` instead of `"$@"` so the arg-scanning result is consistent (or keep `"$@"` since dry_run=0 means no +test was present and `user_args` == `$@`). Simplest: keep `exec` using `"$@"` unchanged — the dry_run block exits early, so exec is only reached when `+test` was never in `$@`.

Verify tests PASS (GREEN): `bats tests/copilot.bats`
  </action>
  <verify>
    <automated>bats tests/copilot.bats</automated>
  </verify>
  <done>All existing tests pass. DRY-RUN-01 through DRY-RUN-05 tests pass. `copilot-plus +test --model gpt-4o myarg` prints `copilot --model gpt-4o myarg` to stdout with no stub execution.</done>
</task>

</tasks>

<verification>
Run full test suite: `bats tests/copilot.bats`
All tests should pass including the 5 new DRY-RUN tests and all existing CONF/MAP/INVK/EXT/ERG tests.
</verification>

<success_criteria>
- `copilot-plus +test <args>` prints the full copilot command to stdout and exits 0 without calling copilot
- `+test` flag is stripped from the printed command output
- All 5 new DRY-RUN bats tests pass
- All pre-existing bats tests continue to pass (zero regressions)
</success_criteria>

<output>
After completion, create `.planning/quick/3-add-test-option-to-copilot-plus-that-out/3-SUMMARY.md`
</output>
