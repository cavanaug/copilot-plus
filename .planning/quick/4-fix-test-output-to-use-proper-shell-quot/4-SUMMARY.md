---
phase: quick-4
plan: 01
subsystem: copilot-plus/dry-run
tags: [shell-quoting, dry-run, printf, bats, tdd]
dependency_graph:
  requires: [quick-3 (+test dry-run flag)]
  provides: [shell-safe dry-run output]
  affects: [copilot-plus, tests/copilot.bats]
tech_stack:
  added: []
  patterns: ["printf '%q' for shell-safe arg output"]
key_files:
  modified:
    - copilot-plus
    - tests/copilot.bats
decisions:
  - "Use printf '%q' not printf '%s' — POSIX-standard shell quoting that leaves safe strings unchanged while escaping shell-special chars"
metrics:
  duration: "~5 min"
  completed: "2026-03-03"
  tasks_completed: 2
  files_modified: 2
---

# Quick Task 4: Fix +test dry-run output to use shell-quoting — Summary

**One-liner:** Shell-safe dry-run output via `printf '%q'` so `+test` output is copy-paste executable for values containing parens, colons, and glob patterns.

## What Was Done

Changed the `copilot-plus` `+test` dry-run output loop from `printf ' %s'` to `printf ' %q'` so argument values with shell-special characters are backslash-escaped in the printed command. Added a new bats test (DRY-RUN-06) that verifies a config value of `shell(git:*)` is output as `shell\(git:\*\)`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fix dry-run printf to use %q shell quoting | 8b1b3b9 | copilot-plus |
| 2 | Add DRY-RUN-06 bats test for special-char shell quoting | 9e839f0 | tests/copilot.bats |

## Verification

- `copilot +test myarg` → `copilot myarg` ✅ (safe strings unchanged)
- `copilot +test` with `--thread=shell(git:*)` → output contains `shell\(git:\*\)` ✅
- All 6 DRY-RUN tests pass ✅
- Full suite 43/43 pass, zero regressions ✅

## Deviations from Plan

None — plan executed exactly as written.

## Key Decisions

- **`printf '%q'` drop-in replacement:** The change is a one-character format specifier swap. `printf '%q'` is POSIX-standard and available in bash 4+. Safe strings (plain words, `--flags`, `word.word`) pass through unchanged — no over-quoting.

## Self-Check

- [x] `copilot-plus` uses `printf ' %q'` at line 145
- [x] `tests/copilot.bats` contains DRY-RUN-06 test
- [x] Commit 8b1b3b9 exists (Task 1)
- [x] Commit 9e839f0 exists (Task 2)
- [x] 43/43 bats tests pass

## Self-Check: PASSED
