# S02: Per Project Config File Support

**Goal:** Extend the `copilot-cli` wrapper with per-project config support and `COPILOT_ARGS` export using TDD.
**Demo:** Extend the `copilot-cli` wrapper with per-project config support and `COPILOT_ARGS` export using TDD.

## Must-Haves


## Tasks

- [x] **T01: 02-per-project-config-file-support 01** `est:12min`
  - Extend the `copilot-cli` wrapper with per-project config support and `COPILOT_ARGS` export using TDD.

Purpose: Allow projects to place a `.copilot/config.json` in their root directory to inject project-specific CLI flags. The project config merges with the global config additively, with key-level override (project wins when same key appears in both). After assembling the full set of config-injected flags, export them as `COPILOT_ARGS` (shell-quoted, space-separated) so nested copilot invocations can use `copilot $COPILOT_ARGS` to inherit the same launch context.

Output:
- `copilot-cli` — updated wrapper script with per-project config merge logic and `COPILOT_ARGS` export
- `tests/copilot.bats` — extended test suite with new tests covering EXT-01 and ERG-03 scenarios (existing 18 tests must continue to pass)

## Files Likely Touched

- `copilot-cli`
- `tests/copilot.bats`
