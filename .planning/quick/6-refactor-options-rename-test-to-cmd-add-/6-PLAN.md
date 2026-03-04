---
phase: quick-6
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus
  - tests/copilot.bats
autonomous: true
requirements: []

must_haves:
  truths:
    - "+cmd prints the full command with double-quoted args and exits (no exec)"
    - "+env prints the COPILOT_ARGS value and exits"
    - "+verbose prints cmd line and COPILOT_ARGS then falls through to exec copilot (does NOT exit)"
    - "+help prints the + options help block and exits"
    - "No + option appears in the args passed to copilot"
    - "All existing tests pass with +test renamed to +cmd"
  artifacts:
    - path: copilot-plus
      provides: "Refactored + option handling block"
      contains: "+cmd +env +verbose +help"
    - path: tests/copilot.bats
      provides: "Tests for all four + options"
      contains: "DRY-RUN +cmd +env +verbose +help"
  key_links:
    - from: "copilot-plus option-parsing loop"
      to: "exec copilot line"
      via: "+verbose sets verbose=1 but does NOT set exit flag; falls through to exec"
---

<objective>
Refactor the `+` option handling in `copilot-plus`:
- Rename `+test` → `+cmd` (same dry-run behavior, new name)
- Add `+env` (print COPILOT_ARGS, exit)
- Add `+verbose` (print cmd + COPILOT_ARGS, then **continue** to exec)
- Add `+help` (print + options help, exit)

Purpose: Make the diagnostic options more discoverable and consistent.
Output: Updated `copilot-plus` with four + options; updated `tests/copilot.bats` with +test→+cmd rename and new tests.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode.gsd/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Refactor + option handling in copilot-plus</name>
  <files>copilot-plus</files>
  <action>
Replace the existing `+test` block (lines 147-166) with a new multi-option parsing block.

**Parsing loop** — scan all args in `"$@"`, strip any `+`-prefixed options before passing to copilot:

```bash
# Parse + options from user args; strip them before passing to copilot
do_cmd=0
do_env=0
do_verbose=0
do_help=0
user_args=()
for arg in "$@"; do
  case "$arg" in
    +cmd)     do_cmd=1 ;;
    +env)     do_env=1 ;;
    +verbose) do_verbose=1 ;;
    +help)    do_help=1 ;;
    *)        user_args+=("$arg") ;;
  esac
done
```

**+help** (check first so it works even with bad args):
```bash
if [[ "$do_help" -eq 1 ]]; then
  printf 'copilot-plus + options:\n'
  printf '  +cmd      print the command that would be run, then exit\n'
  printf '  +env      print COPILOT_ARGS value, then exit\n'
  printf '  +verbose  print command and COPILOT_ARGS, then run normally\n'
  printf '  +help     show this help\n'
  exit 0
fi
```

**Shared print_cmd helper** (used by +cmd and +verbose):
```bash
print_cmd() {
  local cmd=(copilot "${config_flags[@]+"${config_flags[@]}"}" "${user_args[@]+"${user_args[@]}"}")
  printf '%s' "${cmd[0]}"
  for part in "${cmd[@]:1}"; do
    printf ' "%s"' "${part//\"/\\\"}"
  done
  printf '\n'
}
```

**+cmd** (exit after printing):
```bash
if [[ "$do_cmd" -eq 1 ]]; then
  print_cmd
  exit 0
fi
```

**+env** (print COPILOT_ARGS, exit):
```bash
if [[ "$do_env" -eq 1 ]]; then
  printf '%s\n' "$COPILOT_ARGS"
  exit 0
fi
```

**+verbose** (print both, then fall through — NO exit):
```bash
if [[ "$do_verbose" -eq 1 ]]; then
  printf '[copilot-plus] cmd: '
  print_cmd
  printf '[copilot-plus] env: COPILOT_ARGS=%s\n' "$COPILOT_ARGS"
  # intentionally no exit — falls through to exec below
fi
```

**Final exec line** must use `user_args` (not `"$@"`) so stripped + options don't reach copilot:
```bash
exec copilot "${config_flags[@]+"${config_flags[@]}"}" "${user_args[@]+"${user_args[@]}"}"
```

IMPORTANT: When `+verbose` is active, the final exec MUST still run. Do NOT add an exit after the verbose block.
  </action>
  <verify>
    <automated>bash -c 'bash copilot-plus +help' 2>&1 | grep -q "+cmd"</automated>
  </verify>
  <done>
    - `copilot-plus +help` prints the four options and exits
    - `copilot-plus +cmd myarg` prints the command line and exits without calling copilot
    - `copilot-plus +env` prints COPILOT_ARGS value and exits
    - `copilot-plus +verbose myarg` prints diagnostics AND runs copilot (exec path reached)
    - No + options appear in args forwarded to copilot
    - Old `+test` references removed from script
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Update tests — rename +test→+cmd, add tests for +env, +verbose, +help</name>
  <files>tests/copilot.bats</files>
  <behavior>
    - DRY-RUN-01..06: All `+test` → `+cmd` (name change only, same assertions)
    - ENV-01: `+env` with config → prints COPILOT_ARGS value to stdout, stub NOT called
    - ENV-02: `+env` with no config → prints empty string, stub NOT called
    - VERBOSE-01: `+verbose` with config → output contains "[copilot-plus] cmd:" line with copilot + flags, stub IS called
    - VERBOSE-02: `+verbose` does NOT exit — stub_args file exists after run
    - VERBOSE-03: `+verbose` output contains "[copilot-plus] env: COPILOT_ARGS=" line
    - HELP-01: `+help` → prints "copilot-plus + options:" header, exit 0, stub NOT called
    - HELP-02: `+help` output contains all four + option names
  </behavior>
  <action>
**Section 1 — Rename DRY-RUN tests:**
In the six existing DRY-RUN tests (lines 607-672), replace every occurrence of `+test` with `+cmd` in:
- `run_wrapper +test ...` calls
- `[[ "$output" != *"+test"* ]]` assertion → `[[ "$output" != *"+cmd"* ]]`
- Test name strings in `@test "DRY-RUN-NN: +test ..."` → `@test "DRY-RUN-NN: +cmd ..."`

**Section 2 — Add new tests** after the last DRY-RUN test (after line 672):

```bash
# ============================================================
# ENV-01: +env with config → prints COPILOT_ARGS to stdout, stub not called
# ============================================================

@test "ENV-01: +env with config → prints COPILOT_ARGS value to stdout, stub not called" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +env
  [ "$status" -eq 0 ]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# ENV-02: +env with no config → prints empty string, stub not called
# ============================================================

@test "ENV-02: +env with no config → prints empty line, stub not called" {
  run_wrapper +env
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# VERBOSE-01: +verbose with config → prints [copilot-plus] cmd: line
# ============================================================

@test "VERBOSE-01: +verbose with config → output contains cmd line with copilot + flags" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"[copilot-plus] cmd:"* ]]
  [[ "$output" == *"copilot"* ]]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [[ "$output" == *"myarg"* ]]
}

# ============================================================
# VERBOSE-02: +verbose does NOT exit — copilot stub is called
# ============================================================

@test "VERBOSE-02: +verbose does NOT exit — stub is called normally" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# VERBOSE-03: +verbose output contains [copilot-plus] env: COPILOT_ARGS= line
# ============================================================

@test "VERBOSE-03: +verbose output contains [copilot-plus] env: COPILOT_ARGS= line" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"[copilot-plus] env: COPILOT_ARGS="* ]]
}

# ============================================================
# VERBOSE-04: +verbose does not appear in args passed to copilot
# ============================================================

@test "VERBOSE-04: +verbose stripped from args forwarded to copilot" {
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  ! grep -qx "+verbose" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# HELP-01: +help → prints help header, exit 0, stub not called
# ============================================================

@test "HELP-01: +help → prints 'copilot-plus + options:' header, exits 0, stub not called" {
  run_wrapper +help
  [ "$status" -eq 0 ]
  [[ "$output" == *"copilot-plus + options:"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# HELP-02: +help output lists all four + option names
# ============================================================

@test "HELP-02: +help output lists +cmd, +env, +verbose, +help" {
  run_wrapper +help
  [ "$status" -eq 0 ]
  [[ "$output" == *"+cmd"* ]]
  [[ "$output" == *"+env"* ]]
  [[ "$output" == *"+verbose"* ]]
  [[ "$output" == *"+help"* ]]
}
```
  </action>
  <verify>
    <automated>cd /home/cavanaug/wip_other/projects/copilot-cli && bats tests/copilot.bats 2>&1 | tail -5</automated>
  </verify>
  <done>
    - All DRY-RUN tests pass with +cmd (not +test)
    - ENV-01, ENV-02 pass
    - VERBOSE-01, VERBOSE-02, VERBOSE-03, VERBOSE-04 pass
    - HELP-01, HELP-02 pass
    - Full test suite passes with 0 failures
  </done>
</task>

</tasks>

<verification>
Run the full test suite:

```bash
bats tests/copilot.bats
```

Expected: all tests pass (0 failures). Verify manually:
- `bash copilot-plus +cmd foo bar` → prints `copilot "foo" "bar"`
- `COPILOT_ARGS="--model gpt-4.1"; bash copilot-plus +env` → prints `--model gpt-4.1`
- `bash copilot-plus +verbose foo` → prints two `[copilot-plus]` lines then runs copilot
- `bash copilot-plus +help` → prints help block
</verification>

<success_criteria>
- `bats tests/copilot.bats` reports 0 failures
- `+test` no longer exists in `copilot-plus` or `tests/copilot.bats`
- All four + options documented in `+help` output
- `+verbose` falls through to exec (does not exit early)
- `+env` prints exactly what COPILOT_ARGS contains (empty string when no config)
</success_criteria>

<output>
After completion, create `.planning/quick/6-refactor-options-rename-test-to-cmd-add-/6-SUMMARY.md`
</output>
