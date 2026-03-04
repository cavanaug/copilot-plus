---
phase: 02-per-project-config-file-support
plan: 01
subsystem: testing
tags: [bash, jq, bats, config, per-project, COPILOT_ARGS]

# Dependency graph
requires:
  - phase: 01-working-wrapper
    provides: "Global config reading, Phase 1 copilot-cli wrapper with 18 passing tests"
provides:
  - "Per-project config reading from $PWD/.copilot/config.json"
  - "Additive merge with key-level override (project wins for same key)"
  - "COPILOT_ARGS export with shell-quoted, space-separated config-injected flags"
  - "14 new bats tests (EXT-01, ERG-03) with all 32 tests passing"
affects:
  - future-phases
  - copilot-cli-users

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bash nameref (local -n) for passing arrays to functions by reference"
    - "Two-pass config processing: collect project keys first, then process global with skip map"
    - "set -e compatible while loops: use if/then instead of && for boolean tests in loop body"
    - "run_wrapper_in_project: cd to directory for tests that need PWD-based config lookup"
    - "Stub env dump: printf env > file for testing exported env vars like COPILOT_ARGS"

key-files:
  created: []
  modified:
    - "copilot-cli"
    - "tests/copilot.bats"

key-decisions:
  - "Use bash nameref (local -n) for read_config_flags to avoid global variable collision"
  - "Two-call approach: collect project keys first, then read global with skip map — validates project config twice but keeps code clean"
  - "Use if/then not && for boolean checks in while loops under set -e (avoids false exit code propagation in bash 5.2)"
  - "run_wrapper_in_project uses actual cd instead of env PWD= since bash ignores PWD env injection for its own $PWD"
  - "COPILOT_ARGS empty case: check array length first to avoid printf '%q ' outputting quoted-empty string"

patterns-established:
  - "Bash function with namerefs: read_config_flags <file> <array_ref> <skip_keys_assoc_ref>"
  - "set -e safe while loop: use if/then for all boolean conditions that may return false as last statement"
  - "Bats project config tests: cd to project dir using bash -c 'cd dir && env ... bash script'"
  - "Stub env capture: printf stub dumps env to file, tests grep for COPILOT_ARGS= line"

requirements-completed: [EXT-01, ERG-03]

# Metrics
duration: 12min
completed: 2026-03-04
---

# Phase 2 Plan 01: Per-Project Config File Support Summary

**Per-project `.copilot/config.json` support with key-level override merge and `COPILOT_ARGS` export via bash nameref function, all 32 bats tests green**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-04T01:00:14Z
- **Completed:** 2026-03-04T01:12:21Z
- **Tasks:** 3 (RED + GREEN + Smoke)
- **Files modified:** 2

## Accomplishments
- Added `read_config_flags` bash function using namerefs for reusable config reading with key-level override support
- Implemented per-project config merge: global flags (minus overridden keys) + project flags, in that order
- Exported `COPILOT_ARGS` with shell-quoted, space-separated config-injected flags for nested copilot invocations
- Added 14 new bats tests (10 EXT-01 + 4 ERG-03); all 32 tests pass (18 Phase 1 + 14 Phase 2)

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — Add failing tests for per-project config** - `527fa0c` (test)
2. **Task 2: GREEN — Implement per-project config merge** - `62716b1` (feat)
3. **Task 3: Smoke test with real copilot binary** - *(no file changes — verification only)*

## Files Created/Modified
- `copilot-cli` — Refactored to `read_config_flags` function with nameref, two-pass merge (global skip + project), COPILOT_ARGS export
- `tests/copilot.bats` — Updated stub to dump env, added `run_wrapper_in_project` / `write_project_config` helpers, 14 new @test blocks

## Decisions Made
- Used bash nameref (`local -n`) for `read_config_flags` instead of global variables to avoid collision between the two calls (global pass and project pass)
- Two-call approach (validate project config twice) keeps code clean vs single-validation optimization
- `run_wrapper_in_project` uses `bash -c 'cd ... && env ... bash script'` instead of `env PWD=...` because bash computes `$PWD` from actual CWD, ignoring injected `PWD` env vars
- `COPILOT_ARGS` empty guard uses `[[ ${#config_flags[@]} -eq 0 ]]` because `printf '%q '` with no args emits `''` (two-char quoted-empty string) rather than empty string

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed set -e incompatible boolean check in while loop**
- **Found during:** Task 2 (GREEN — implementing copilot-cli)
- **Issue:** `[[ "$val" == "true" ]] && _flags_ref+=("$key")` — when val is false, `[[` returns exit code 1, which becomes the while loop's exit code in bash 5.2, causing the function to return 1, which with set -e causes the caller to exit
- **Fix:** Changed to `if [[ "$val" == "true" ]]; then _flags_ref+=("$key"); fi` and similarly for `[[ -v _skip_ref["$key"] ]] && continue`
- **Files modified:** copilot-cli
- **Verification:** Test 7 (MAP-01+MAP-04: boolean false) now passes; all 32 tests green
- **Committed in:** 62716b1 (Task 2 commit)

**2. [Rule 1 - Bug] Fixed run_wrapper_in_project helper to use actual cd**
- **Found during:** Task 2 (GREEN — running bats tests)
- **Issue:** Plan specified `env PWD="$BATS_TMPDIR/project" bash script` but bash ignores injected `PWD` env var and uses actual CWD for `$PWD`, so project config at `$PWD/.copilot/config.json` was never found
- **Fix:** Changed helper to use `bash -c 'cd ... && env ... bash script'` to actually change directory
- **Files modified:** tests/copilot.bats
- **Verification:** EXT-01 tests (19-28) now pass correctly
- **Committed in:** 62716b1 (Task 2 commit)

**3. [Rule 1 - Bug] Fixed COPILOT_ARGS empty string output**
- **Found during:** Task 2 (GREEN — ERG-03b test failure)
- **Issue:** `printf '%q ' "${config_flags[@]+"${config_flags[@]}"}` outputs `''` (two-char quoted-empty string) when array is empty, not `""` (empty string)
- **Fix:** Added `[[ ${#config_flags[@]} -eq 0 ]]` guard to set COPILOT_ARGS="" directly when no flags
- **Files modified:** copilot-cli
- **Verification:** Test 30 (ERG-03b) now passes
- **Committed in:** 62716b1 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs in plan's code snippets)
**Impact on plan:** All fixes necessary for correctness. The plan's code snippets had subtle bash set -e incompatibilities and a test helper design issue. No scope creep.

## Issues Encountered
- bash 5.2 treats the exit code of `&&` short-circuit expressions as the loop body's exit code, which propagates from `while` to the calling scope under `set -e`. Required switching to explicit `if/then` for any boolean condition that may be false.
- `env PWD=` pattern doesn't change bash's `$PWD` — bash always sets `$PWD` from the kernel-level CWD. The plan's interface section used `env PWD=` but this required a `cd` approach instead.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Per-project config fully functional with 32 passing tests
- COPILOT_ARGS exported and available for nested copilot invocations
- Phase 1 regression-free (all 18 original tests still pass)
- Ready for any Phase 3 work (EXT-02 config path override, ERG-01 debug flag, etc.)

---
*Phase: 02-per-project-config-file-support*
*Completed: 2026-03-04*
