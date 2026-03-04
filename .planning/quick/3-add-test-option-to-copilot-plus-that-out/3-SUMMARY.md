---
phase: quick-3
plan: 3
subsystem: copilot-plus
tags: [dry-run, test-flag, tdd, shell, bash]
dependency_graph:
  requires: []
  provides: [+test dry-run mode in copilot-plus]
  affects: [copilot-plus, tests/copilot.bats]
tech_stack:
  added: []
  patterns: [TDD red-green, +flag convention for copilot-plus-owned options]
key_files:
  created: []
  modified:
    - copilot-plus
    - tests/copilot.bats
decisions:
  - "+test handled entirely in copilot-plus before exec; never passed to copilot (consistent with + prefix convention)"
  - "User args scanned via loop to strip +test; remaining args held in user_args array (reusable if future +flags needed)"
  - "Dry-run output uses printf '%s' / printf ' %s' loop to avoid trailing space without trimming"
metrics:
  duration: 3 min
  completed_date: "2026-03-04"
  tasks_completed: 1
  files_modified: 2
---

# Quick Task 3: Add +test dry-run flag to copilot-plus — Summary

**One-liner:** `+test` dry-run flag detects, strips, and prints the full `copilot` command (config flags + user args) without exec-ing copilot.

## What Was Built

Added `+test` dry-run support to `copilot-plus`. When `+test` appears anywhere in the user's arguments:

1. It is detected and stripped from the arg list
2. The full command that *would* be exec'd (`copilot <config-flags> <remaining-user-args>`) is printed to stdout
3. `copilot-plus` exits 0 without ever calling `copilot`

Without `+test`, behavior is completely unchanged — `exec copilot ...` runs as before.

## Files Modified

| File | Change |
|------|--------|
| `copilot-plus` | Added `+test` detection loop + dry-run print/exit block before `exec` (lines 130–151) |
| `tests/copilot.bats` | Added 5 DRY-RUN tests (DRY-RUN-01 through DRY-RUN-05) |

## Tasks Completed

| # | Task | Commit | Status |
|---|------|--------|--------|
| 1 (RED) | Add failing DRY-RUN bats tests | ae4c6e8 | ✅ |
| 1 (GREEN) | Implement +test dry-run in copilot-plus | f7db0e0 | ✅ |

## Test Results

```
1..42
ok 38 DRY-RUN-01: +test with no config → prints 'copilot' + user args, stub not called
ok 39 DRY-RUN-02: +test with config → prints full command with config flags + user args
ok 40 DRY-RUN-03: +test only, no config, no user args → prints 'copilot'
ok 41 DRY-RUN-04: +test itself does not appear in the printed command
ok 42 DRY-RUN-05: without +test → normal exec, stub called as before
```

All 37 pre-existing tests continue to pass. Total: 42/42.

## Key Decisions

1. **`+test` is a copilot-plus-owned option** — follows the `+` prefix convention; never passed to `copilot`. Detected and stripped entirely within `copilot-plus`.

2. **User arg scanning via loop** — scans all `$@` positional args for `+test`, collects remaining in `user_args`. This pattern is reusable for future `+flags`.

3. **`exec` line unchanged** — the original `exec copilot "${config_flags[@]+"${config_flags[@]}"}" "$@"` is kept as-is. The dry-run block exits early, so `exec` is only reached when `+test` was never present (meaning `user_args == $@`).

4. **Output format** — uses `printf '%s' "${cmd[0]}"` + loop `printf ' %s' "$part"` to avoid trailing space without needing `trimright` logic.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `copilot-plus` modified: ✅
- `tests/copilot.bats` modified: ✅
- Commit ae4c6e8 (RED): ✅
- Commit f7db0e0 (GREEN): ✅
- All 42 tests pass: ✅
