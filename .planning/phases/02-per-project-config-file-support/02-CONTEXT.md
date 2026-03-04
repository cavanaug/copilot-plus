# Phase 2: Per Project Config File Support - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the `copilot-cli` wrapper to also read a per-project config file (`.copilot/config.json` in the current working directory) and merge it with the global config (`~/.copilot/config.json`). The same `--` key convention applies to both config files. Per-project config enables project-specific flag injection without touching the global config.

</domain>

<decisions>
## Implementation Decisions

### Per-project config file location
- Path: `.copilot/config.json` relative to the **current working directory** (i.e. `$PWD/.copilot/config.json`)
- This mirrors the global config structure (`~/.copilot/config.json`) — same directory name, same file name
- Intentionally avoids `.github/copilot/config.json` which is taken by the native Copilot IDE feature (VS Code agent instructions)
- No environment variable override for the path in this phase (EXT-02 is deferred)

### Merge strategy: additive with key-level override
- **Default: additive** — flags from global and project configs are both passed to copilot
- **Key-level override**: if the same `--` key appears in both configs, the **project value replaces the global value** for that key entirely
  - Example: global has `"--allow-tool": ["shell(sed)"]`, project has `"--allow-tool": ["shell(git:*)"]` → only `--allow-tool shell(git:*)` is passed (project wins)
  - Example: global has `"--allow-tool": ["shell(sed)"]`, project has `"--deny-tool": ["shell(rm)"]` → both are passed (different keys, fully additive)
- **Rationale for key-level override**: when a project specifies a key, it means "I want to control this flag for this project" — the global value for that same key is superseded
- **Why additive is safe for allow/deny conflicts**: copilot's `--deny-*` flags always take semantic precedence over `--allow-*` flags regardless of flag order (confirmed: `--deny-url` help text explicitly states "takes precedence over --allow-url"; `--deny-tool` example in help shows deny+allow coexisting with deny winning)

### COPILOT_ARGS export
- After assembling all config-injected flags (global + project merged), export `COPILOT_ARGS` as a shell-quoted, space-separated string
- Enables nested invocations: `copilot $COPILOT_ARGS <new-args>` inherits the same config-injected launch context
- Contains ONLY config-injected flags — NOT user-supplied args (those are session-specific)
- Values with special shell characters (e.g. `shell(git:*)`) are properly quoted via `printf '%q'`
- If no flags are assembled, `COPILOT_ARGS` is exported as empty string
- `COPILOT_ARGS` is set before `exec copilot ...` so it's inherited by the exec'd process

### Flag ordering
- Global flags are processed first, project flags second
- Within each config, keys are processed in JSON key order (as returned by `jq keys[]`)
- Config-injected flags (global + project combined) are prepended to user-supplied args (same as Phase 1)

### Error handling
- Same rules as Phase 1 apply to both config files independently:
  - Missing or unreadable → silent passthrough (no flags from that source)
  - Invalid JSON → exit with clear error message before invoking copilot
  - Unsupported value type (object, null) → exit with clear error message

### Implementation approach
- Extract the config-reading logic into a reusable bash function `read_config_flags <file> <array_name_ref>`
- Call it once for global, once for project; merge results with key-level override logic before building final flag array
- Key-level override is implemented by tracking which keys were seen in project config and suppressing those keys from global output

</decisions>

<specifics>
## Specific Ideas

- The function approach keeps the script readable and avoids duplicating the type-dispatch logic
- Key-level override can be implemented by: (1) collect project keys into an associative array, (2) when processing global keys, skip any key that appears in the project config's `--` keys

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `copilot-cli` — the existing wrapper (45 lines), all Phase 1 logic intact
- `tests/copilot.bats` — 18 passing bats tests; new tests will be added to this file

### Established Patterns
- Config reading: `jq -r 'keys[] | select(startswith("--"))' "$CONFIG_FILE"` to iterate `--` keys
- Type dispatch: `jq -r --arg k "$key" '.[$k] | type'` → case statement
- Array handling: `jq -r --arg k "$key" '.[$k][]'` to iterate elements
- Error format: `copilot-wrapper: error: <message>` to stderr, exit 1
- Silent passthrough: `[[ -f "$file" ]] && [[ -r "$file" ]]` guard
- Exec invocation: `exec copilot "${config_flags[@]+"${config_flags[@]}"}" "$@"`
- Test stub: `PATH="$BATS_TMPDIR/bin:$PATH" HOME="$BATS_TMPDIR"` injection

### Integration Points
- Global config: `${HOME}/.copilot/config.json`
- Project config: `${PWD}/.copilot/config.json`
- Real copilot binary: resolved via `exec copilot` (PATH-based, no hardcoded path)

</code_context>

<deferred>
## Deferred Ideas

- **EXT-02**: `COPILOT_WRAPPER_CONFIG` env var to override config path — deferred to future phase
- **ERG-01**: `--wrapper-debug` flag — deferred to future phase
- **ERG-02**: `--available-tools` space-separated variant — deferred to future phase

</deferred>

---

*Phase: 02-per-project-config-file-support*
*Context gathered: 2026-03-04*
