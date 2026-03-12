# T01: 02-per-project-config-file-support 01

**Slice:** S02 — **Milestone:** M001

## Description

Extend the `copilot-cli` wrapper with per-project config support and `COPILOT_ARGS` export using TDD.

Purpose: Allow projects to place a `.copilot/config.json` in their root directory to inject project-specific CLI flags. The project config merges with the global config additively, with key-level override (project wins when same key appears in both). After assembling the full set of config-injected flags, export them as `COPILOT_ARGS` (shell-quoted, space-separated) so nested copilot invocations can use `copilot $COPILOT_ARGS` to inherit the same launch context.

Output:
- `copilot-cli` — updated wrapper script with per-project config merge logic and `COPILOT_ARGS` export
- `tests/copilot.bats` — extended test suite with new tests covering EXT-01 and ERG-03 scenarios (existing 18 tests must continue to pass)

## Must-Haves

- [ ] "Running `copilot-cli myarg` with only a project config `.copilot/config.json` containing `\"--allow-tool\": [\"bash\"]` causes `--allow-tool bash` to reach copilot"
- [ ] "Running `copilot-cli myarg` with only a global config `~/.copilot/config.json` still works as before (Phase 1 behavior unchanged)"
- [ ] "Running `copilot-cli myarg` with both global and project configs causes flags from BOTH to be passed (additive for different keys)"
- [ ] "When global and project configs share the same `--` key, only the project value is used for that key (key-level override)"
- [ ] "Missing project config → silent passthrough (no flags from project source, global still applied)"
- [ ] "Invalid JSON in project config → exit non-zero with error to stderr, copilot not called"
- [ ] "Object/null value in project config → exit non-zero with error to stderr, copilot not called"
- [ ] "Global flags come before project flags in the final argument list"
- [ ] "After flag assembly, `COPILOT_ARGS` is exported containing all config-injected flags shell-quoted and space-separated"
- [ ] "A nested `copilot $COPILOT_ARGS <new-args>` invocation receives the same config-injected flags as the original call"
- [ ] "`COPILOT_ARGS` contains only config-injected flags — NOT user-supplied args"

## Files

- `copilot-cli`
- `tests/copilot.bats`
