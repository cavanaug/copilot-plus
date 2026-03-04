---
phase: quick-6
plan: 01
subsystem: copilot-plus
tags: [refactor, ux, diagnostics, shell]
dependency_graph:
  requires: []
  provides: ["+cmd dry-run option", "+env COPILOT_ARGS inspector", "+verbose diagnostic passthrough", "+help option discovery"]
  affects: [copilot-plus, tests/copilot.bats]
tech_stack:
  added: []
  patterns: ["case-based + option parsing", "print_cmd shared helper", "fall-through exec pattern for +verbose"]
key_files:
  modified:
    - copilot-plus
    - tests/copilot.bats
decisions:
  - "Shared print_cmd() helper avoids duplication between +cmd and +verbose"
  - "Fall-through pattern for +verbose (no exit) naturally reuses existing exec line"
  - "+help checked first so it works even with other bad args present"
  - "user_args array accumulates non-+ args so all + options are stripped before exec"
metrics:
  duration: 2 min
  completed: "2026-03-04T04:53:23Z"
  tasks: 2
  files: 2
---

# Quick Task 6: Refactor + Options — Rename +test to +cmd, Add +env +verbose +help

**One-liner:** Replaced single `+test` dry-run with four discoverable diagnostic options (`+cmd`, `+env`, `+verbose`, `+help`) using a case-loop strip-and-dispatch pattern.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Refactor + option handling in copilot-plus | 974c9c1 | copilot-plus |
| 2 | Update tests — rename +test→+cmd, add ENV/VERBOSE/HELP tests | dd3864d | tests/copilot.bats |

## What Was Built

### copilot-plus changes

Replaced the single `+test` dry-run block (lines 147-166) with a structured multi-option system:

1. **Parsing loop** — `case` statement scans all `"$@"`, sets `do_cmd/do_env/do_verbose/do_help` flags, and builds `user_args` array with all non-`+` args
2. **`+help`** — Checked first; prints four-option summary and exits
3. **`print_cmd()` helper** — Shared function builds and prints the copilot command line with double-quoted args; used by both `+cmd` and `+verbose`
4. **`+cmd`** — Calls `print_cmd`, exits (dry-run, no exec)
5. **`+env`** — Prints `$COPILOT_ARGS` value and exits
6. **`+verbose`** — Calls `print_cmd`, prints COPILOT_ARGS line, then falls through (no exit) to the `exec copilot` line below
7. **Final exec** — Uses `user_args` (not `"$@"`) so all `+` options are stripped before reaching copilot

### tests/copilot.bats changes

- **DRY-RUN-01..06**: All `+test` → `+cmd` (name change only, same assertions)
- **ENV-01**: `+env` with config → prints COPILOT_ARGS value, stub not called
- **ENV-02**: `+env` with no config → prints empty string, stub not called
- **VERBOSE-01**: `+verbose` output contains `[copilot-plus] cmd:` line with flags
- **VERBOSE-02**: `+verbose` does NOT exit — stub is called, stub_args exists
- **VERBOSE-03**: `+verbose` output contains `[copilot-plus] env: COPILOT_ARGS=` line
- **VERBOSE-04**: `+verbose` not forwarded to copilot (stripped from args)
- **HELP-01**: `+help` prints `copilot-plus + options:` header, exit 0, stub not called
- **HELP-02**: `+help` output lists all four option names

## Test Results

```
1..54
ok 41–46: DRY-RUN-01..06 (renamed +cmd)
ok 47–48: ENV-01..02
ok 49–52: VERBOSE-01..04
ok 53–54: HELP-01..02
54 tests, 0 failures
```

## Deviations from Plan

None — plan executed exactly as written.

## Success Criteria Verification

- [x] `bats tests/copilot.bats` reports 0 failures (54 tests)
- [x] `+test` no longer exists in `copilot-plus` (0 occurrences)
- [x] `+test` no longer exists in `tests/copilot.bats` (0 occurrences)
- [x] All four + options documented in `+help` output
- [x] `+verbose` falls through to exec (does not exit early) — confirmed by VERBOSE-02
- [x] `+env` prints exactly what COPILOT_ARGS contains (empty string when no config) — confirmed by ENV-02

## Self-Check: PASSED

- [x] copilot-plus modified: `grep "+test" copilot-plus` → 0 matches
- [x] tests/copilot.bats modified: `grep "+test" tests/copilot.bats` → 0 matches
- [x] Commit 974c9c1 exists: `git log --oneline | grep 974c9c1` ✓
- [x] Commit dd3864d exists: `git log --oneline | grep dd3864d` ✓
