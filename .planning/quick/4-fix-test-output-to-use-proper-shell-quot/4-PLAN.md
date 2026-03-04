---
phase: quick-4
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus
  - tests/copilot.bats
autonomous: true
requirements: [QUICK-4]
must_haves:
  truths:
    - "+test output for special-char values (parens, colons, globs, spaces) is shell-quoted and copy-paste executable"
    - "+test output for safe strings (plain words, --flags, word.word) is unchanged — no over-quoting"
    - "All existing DRY-RUN bats tests still pass"
    - "At least one new test validates quoting of a value containing special characters"
  artifacts:
    - path: "copilot-plus"
      provides: "Shell-quoted dry-run output using printf '%q'"
    - path: "tests/copilot.bats"
      provides: "DRY-RUN test covering special-char quoting"
  key_links:
    - from: "copilot-plus dry-run block (lines 141-149)"
      to: "printf '%q'"
      via: "replace 'printf \" %s\"' with 'printf \" %q\"' in the loop"
---

<objective>
Fix the `+test` dry-run output in `copilot-plus` to use `printf '%q'` for shell-quoting all args after the command name, so values with special characters (parens, colons, glob patterns, spaces) are properly escaped and the entire output line is copy-paste executable.

Purpose: Users who run `copilot +test` to preview their command should be able to copy-paste the output directly into a terminal without shell interpretation errors.
Output: Updated `copilot-plus` with `printf '%q'`, and a new bats test confirming special-char quoting works.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode.gsd/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@copilot-plus
@tests/copilot.bats
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix dry-run printf to use %q shell quoting</name>
  <files>copilot-plus</files>
  <action>
In the dry-run block (lines 141-149), change the argument-printing loop to use `printf '%q'` instead of `printf ' %s'`.

Current code (lines 141-149):
```bash
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

Replace with:
```bash
if [[ "$dry_run" -eq 1 ]]; then
  cmd=(copilot "${config_flags[@]+"${config_flags[@]}"}" "${user_args[@]+"${user_args[@]}"}")
  printf '%s' "${cmd[0]}"
  for part in "${cmd[@]:1}"; do
    printf ' %q' "$part"
  done
  printf '\n'
  exit 0
fi
```

The ONLY change is `' %s'` → `' %q'` in the loop body.

**Key behavior of `printf '%q'`:** Safe strings like `myarg`, `--model`, `gpt-4.1`, `--flag=value` are output UNCHANGED. Only strings with shell-special characters (spaces, parens, colons, globs `*?[]`, `$`, backticks, etc.) are escaped with backslash notation, making them safe for copy-paste into any POSIX shell.
  </action>
  <verify>
    <automated>
# Quick smoke tests before running full suite
bash -c 'cd "$(git rev-parse --show-toplevel)" && bash copilot-plus +test myarg 2>/dev/null | grep -qx "copilot myarg" && echo "safe-string: PASS"'
bash -c 'cd "$(git rev-parse --show-toplevel)" && COPILOT_HOME=$(mktemp -d) && printf '"'"'{"--model":"gpt-4.1"}'"'"' > "$COPILOT_HOME/config.json" && HOME="$COPILOT_HOME" bash copilot-plus +test myarg 2>/dev/null | tee /dev/stderr'
    </automated>
  </verify>
  <done>The loop uses `printf ' %q'`; running `copilot-plus +test myarg` still outputs `copilot myarg` (no change for safe strings)</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add DRY-RUN-06 bats test for special-character shell quoting</name>
  <files>tests/copilot.bats</files>
  <behavior>
    - Test: config with `--thread` set to `shell(git:*)` → +test output contains the value shell-quoted as `shell\(git:\*\)` (backslash-escaped parens, colon, glob star)
    - This verifies the value is safe for copy-paste execution and not output raw
  </behavior>
  <action>
Append a new test block after the last DRY-RUN-05 test (after line 620). Do NOT modify any existing tests.

Add at the end of the file:

```bash

# ============================================================
# DRY-RUN-06: +test with special-char value → value is shell-quoted
# ============================================================

@test "DRY-RUN-06: +test with special-char config value → value is shell-quoted in output" {
  write_config '{"--thread":"shell(git:*)"}'
  run_wrapper +test
  [ "$status" -eq 0 ]
  [[ "$output" == *'shell\(git:\*\)'* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}
```

**Why this test:** `shell(git:*)` contains parens, colon, and glob — all shell-special. `printf '%q'` must escape them. The test verifies the exact escaped form appears in output, confirming the value is safe to copy-paste.

**Note on existing tests:** All current DRY-RUN tests still pass because `printf '%q'` on safe strings (`myarg`, `--model`, `gpt-4.1`) produces identical output to `printf '%s'`. Verified:
- `printf '%q' myarg` → `myarg` (unchanged)
- `printf '%q' --model` → `--model` (unchanged)  
- `printf '%q' gpt-4.1` → `gpt-4.1` (unchanged)

No existing tests require modification.
  </action>
  <verify>
    <automated>bats tests/copilot.bats --filter "DRY-RUN"</automated>
  </verify>
  <done>All 6 DRY-RUN tests pass. DRY-RUN-06 specifically validates that `shell(git:*)` is output as `shell\(git:\*\)` in the dry-run command line.</done>
</task>

</tasks>

<verification>
Run the full DRY-RUN test suite to confirm all 6 tests pass:

```bash
bats tests/copilot.bats --filter "DRY-RUN"
```

Expected: 6 tests, 0 failures.

Also run the full test suite to confirm no regressions:

```bash
bats tests/copilot.bats
```
</verification>

<success_criteria>
- `copilot-plus` dry-run loop uses `printf ' %q'` (not `' %s'`)
- `copilot +test myarg` still outputs `copilot myarg` (safe strings unaffected)
- `copilot +test` with `--thread=shell(git:*)` outputs `shell\(git:\*\)` (special chars escaped)
- All DRY-RUN bats tests (01-06) pass
- Full bats suite has zero regressions
</success_criteria>

<output>
After completion, create `.planning/quick/4-fix-test-output-to-use-proper-shell-quot/4-SUMMARY.md`
Update `.planning/STATE.md` to record quick task 4 completion.
</output>
