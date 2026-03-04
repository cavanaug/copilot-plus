---
phase: quick
plan: 1
subsystem: copilot-cli
tags: [bash, upward-search, project-config, add-dir, tdd]
dependency_graph:
  requires: []
  provides: [upward-project-config-discovery, auto-add-dir-injection]
  affects: [copilot-cli, tests/copilot.bats]
tech_stack:
  added: []
  patterns: [find_project_config-upward-walk, HOME-boundary-stop, git-boundary-stop]
key_files:
  created: []
  modified:
    - copilot-cli
    - tests/copilot.bats
decisions:
  - "HOME boundary check in find_project_config prevents global ~/.copilot/ from being treated as project config when tests set HOME=$BATS_TMPDIR"
  - "Search stops at .git/ boundary (git root) before reaching HOME, ensuring monorepos use the nearest git-root project config"
  - "auto --add-dir injected after project config flags so project flags maintain precedence ordering"
metrics:
  duration: "~5 min"
  completed: "2026-03-04T02:02:14Z"
  tasks_completed: 2
  files_modified: 2
---

# Quick Plan 1: Upward Search for .copilot/ + Auto --add-dir Summary

**One-liner:** Upward directory walk from `$PWD` finds nearest `.copilot/config.json` ancestor; containing dir auto-injected as `--add-dir` with HOME and `.git/` boundary stops.

## What Was Built

Replaced the hardcoded `PROJECT_CONFIG="${PWD}/.copilot/config.json"` assignment in `copilot-cli` with a `find_project_config()` bash function that walks upward from `$PWD`. The found project root is auto-injected as `--add-dir` into `config_flags`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Add failing EXT-02* bats tests | bfe2a48 | tests/copilot.bats |
| 2 (GREEN) | Implement find_project_config() + auto --add-dir | 3206414 | copilot-cli |

## Implementation Details

### `find_project_config()` logic

```
$PWD → check .copilot/ (found → use it) → check .git/ (stop, no config) → check HOME boundary (stop) → go to parent → repeat
```

Boundary stops (in order):
1. `.copilot/` found → set `PROJECT_CONFIG` + `PROJECT_ROOT`, return
2. `.git/` found → clear both, return (git root without `.copilot/`)
3. `$parent == $HOME` or `$dir == $HOME` → clear both, return (global config boundary)
4. `$parent == $dir` → filesystem root, clear both, return

### Auto `--add-dir` injection

After `read_config_flags "$PROJECT_CONFIG"`, if `$PROJECT_ROOT` is non-empty:
```bash
config_flags+=("--add-dir" "$PROJECT_ROOT")
```

This means:
- `COPILOT_ARGS` also contains the `--add-dir` flag (it's part of `config_flags`)
- Ordering: global flags → project config flags → `--add-dir PROJECT_ROOT`

## Test Coverage

37 total tests, all passing:
- EXT-02a: subdirectory finds parent `.copilot/config.json` → flags injected ✅
- EXT-02b: subdirectory run → parent dir auto-injected as `--add-dir` ✅
- EXT-02c: project root run → project root auto-injected as `--add-dir` ✅
- EXT-02d: `.git/` boundary, no `.copilot/` → silent passthrough ✅
- EXT-02e: `.git/` + `.copilot/` both present → config used + `--add-dir` injected ✅
- All 32 pre-existing tests still pass ✅

## Deviations from Plan

**1. [Rule 1 - Bug] HOME boundary prevents EXT-01b from breaking**

- **Found during:** Task 2 analysis (plan already called this out)
- **Issue:** Without HOME boundary, upward walk from `$BATS_TMPDIR/project` would reach `$BATS_TMPDIR` (which equals `$HOME` in tests) and pick up global `$BATS_TMPDIR/.copilot/` as a project config, breaking EXT-01b
- **Fix:** Added `if [[ "$parent" == "$HOME" ]] || [[ "$dir" == "$HOME" ]]` boundary check (plan specified this fix)
- **Files modified:** copilot-cli
- **Commit:** 3206414

None beyond what the plan anticipated — plan executed exactly as written.

## Self-Check

- [x] `find_project_config` function exists in `copilot-cli`
- [x] `bats tests/copilot.bats` exits 0 with all 37 tests passing
- [x] Commits bfe2a48 and 3206414 exist
