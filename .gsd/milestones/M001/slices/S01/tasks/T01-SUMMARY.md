---
id: T01
parent: S01
milestone: M001
provides:
  - "copilot wrapper bash script with general-purpose -- key convention"
  - "bats test suite covering all 16 v1 requirements (18 test cases)"
requires: []
affects: []
key_files: []
key_decisions: []
patterns_established: []
observability_surfaces: []
drill_down_paths: []
duration: 4min
verification_result: passed
completed_at: 2026-03-04
blocker_discovered: false
---
# T01: 01-working-wrapper 01

**# Phase 1 Plan 01: Working Wrapper Summary**

## What Happened

# Phase 1 Plan 01: Working Wrapper Summary

**Single bash wrapper using jq type-dispatch (`array`/`boolean`/`string`/`number`→flags, `object`/`null`→error) to inject `--`-prefixed config keys as CLI flags before exec-replacing with the real copilot binary — all 18 bats tests pass**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-04T00:29:08Z
- **Completed:** 2026-03-04T00:33:49Z
- **Tasks:** 3 (RED, GREEN, smoke test)
- **Files modified:** 2

## Accomplishments
- Full TDD cycle: RED (18 failing tests) → GREEN (18 passing tests)
- `copilot` wrapper script: 46 lines, general-purpose `--` key convention, no hardcoded flag table
- `tests/copilot.bats`: 18 test cases covering all 16 v1 requirements
- All 6 smoke tests against real copilot binary pass (passthrough, injection, error cases)
- `exec` semantics confirmed: wrapper process is replaced, not a subprocess

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — Write failing bats test suite** - `982e7be` (test)
2. **Task 2: GREEN — Implement the copilot wrapper script** - `916bc6d` (feat)

_Note: Task 3 (smoke test) produced no file changes — verification only_

## Files Created/Modified
- `copilot` — Executable bash wrapper script; reads `~/.copilot/config.json`, injects `--`-prefixed keys as CLI flags via jq type dispatch, exec-replaces with real copilot binary
- `tests/copilot.bats` — bats test suite; 18 @test blocks covering all CONF/MAP/INVK/DIST requirements; uses COPILOT_REAL_BINARY env var for stub isolation

## Decisions Made
- **COPILOT_REAL_BINARY env override:** The plan spec shows `REAL_COPILOT=/home/linuxbrew/.linuxbrew/bin/copilot` (hardcoded absolute path) AND a stub pattern relying on PATH interception. These are contradictory — absolute path exec bypasses PATH. Solution: `COPILOT_REAL_BINARY` env var overrides the default absolute path, allowing tests to point at the stub binary. Default behavior unchanged for production use.
- **exec semantics via env override:** Rather than changing exec to use PATH lookup (which risks infinite self-calls), the env var approach is both safe and testable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test stub interception incompatibility with hardcoded REAL_COPILOT path**
- **Found during:** Task 2 (GREEN — first bats run after creating `copilot` script)
- **Issue:** Plan spec shows `REAL_COPILOT=/home/linuxbrew/.linuxbrew/bin/copilot` (absolute path) AND test stub pattern that prepends `$BATS_TMPDIR/bin` to PATH. The absolute path exec bypasses PATH entirely — stub was never called.
- **Fix:** Added `COPILOT_REAL_BINARY` env var override in the wrapper (`${COPILOT_REAL_BINARY:-/home/linuxbrew/.linuxbrew/bin/copilot}`); updated test helper to set `COPILOT_REAL_BINARY="$BATS_TMPDIR/bin/copilot"`. Also fixed bats stub generation (heredoc has shell expansion issues in bats — switched to printf with explicit path interpolation).
- **Files modified:** `copilot`, `tests/copilot.bats`
- **Verification:** All 18 bats tests pass
- **Committed in:** `916bc6d` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Necessary correction — the plan's test stub pattern was incompatible with the hardcoded exec target. Env override is minimal, doesn't change production behavior.

## Issues Encountered
- bats heredoc expansion issue: `cat << 'STUB'` in `setup()` doesn't expand `$BATS_TMPDIR` inside the stub script content. Switched to `printf` with explicit path interpolation.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 1 complete — all 16 v1 requirements implemented and tested
- `copilot` wrapper ready to be placed earlier in `$PATH` than the real copilot binary
- User needs to `chmod +x copilot` and copy to a directory earlier in `$PATH` (e.g. `~/bin/`)
- All v2 requirements (EXT-01..03, ERG-01..02) remain for future phases

---
*Phase: 01-working-wrapper*
*Completed: 2026-03-04*
