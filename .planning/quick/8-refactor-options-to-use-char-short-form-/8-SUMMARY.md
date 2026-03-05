---
phase: quick
plan: 8
subsystem: cli-options
tags: [refactor, cli, options, bash]
dependency_graph:
  requires: []
  provides: [++word/+char option convention in copilot-plus]
  affects: [copilot-plus]
tech_stack:
  added: []
  patterns: [++word long form / +char short form CLI convention]
key_files:
  created: []
  modified: [copilot-plus]
decisions:
  - "++word for long forms, +char for short forms (capital +V for verbose to avoid collision with +v=version)"
  - "Old bare +word forms cleanly removed — personal tool, clean break"
metrics:
  duration: "3 min"
  completed: "2026-03-05"
---

# Phase quick Plan 8: Refactor Options to Use +char Short Form Summary

**One-liner:** Replaced `+word` single-form CLI options with `++word` (long) / `+char` (short) convention throughout `copilot-plus`.

## What Was Built

Refactored all + option handling in `copilot-plus` to use the `++word` / `+char` dual-form convention, matching standard `-v`/`--verbose` CLI idiom adapted for the `+` prefix namespace:

| Old form   | New long    | New short |
|------------|-------------|-----------|
| `+cmd`     | `++cmd`     | `+c`      |
| `+env`     | `++env`     | `+e`      |
| `+verbose` | `++verbose` | `+V`      |
| `+help`    | `++help`    | `+h`      |
| `+version` | `++version` | `+v`      |

Note: `+V` (capital) used for verbose to avoid collision with `+v` (version).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Replace + option handling in copilot-plus | 65c56a6 | copilot-plus |

## Changes Made

### copilot-plus

1. **Section comment** updated: `# Parse + options` → `# Parse ++ / + options`
2. **Case statement** replaced — old single `+word)` arms replaced with `++word|+char)` dual-form arms; old `+v` alias line removed (folded into `++version|+v`)
3. **Help printf block** updated: header `copilot-plus ++ options:`, all lines show `++word, +char` aligned format, old `+v alias` line removed
4. **Handler-block comments** updated for all five option handlers

## Verification

All automated checks passed:
- `++cmd`, `++env`, `++verbose`, `++help`, `++version` present ✓
- `+c`, `+e`, `+V`, `+h` short forms present in case arms ✓
- Old bare `+cmd)`, `+env)`, `+verbose)`, `+help)` case arms gone ✓
- `bash copilot-plus +h` shows `++help` in output ✓
- `bash copilot-plus ++help` shows `++help` in output ✓
- `bash copilot-plus +v` prints version ✓
- `bash copilot-plus ++version` prints version ✓
- `bash copilot-plus ++cmd echo hello` prints command ✓
- `bash copilot-plus +c echo hello` prints command ✓

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- File `copilot-plus` modified ✓
- Commit `65c56a6` exists ✓
