# Phase 1: Working Wrapper - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A single bash script named `copilot`, placed earlier in `$PATH` than the real copilot binary. It reads `~/.copilot/config.json` at invocation time and execs the real binary with injected flags. No subprocesses, no output buffering — fully transparent invocation.

</domain>

<decisions>
## Implementation Decisions

### Config key convention
- Keys in `~/.copilot/config.json` that start with `--` are treated as CLI flags to inject
- This is a **general-purpose mechanism** — no hardcoded mapping table
- Example: `"--allow-tool": ["shell(git:*)", "write"]` → `--allow-tool 'shell(git:*)' --allow-tool write`
- Any `--` key is passed through, even if not a recognized copilot flag (user's responsibility)

### Value type handling
- **Array** → one `--key value` pair per element (the primary use case)
- **Boolean `true`** → bare flag injected with no value (e.g. `"--yolo": true` → `--yolo`)
- **Boolean `false`** → key is skipped entirely
- **String** → treated as single-item: `"--model": "gpt-4.1"` → `--model gpt-4.1`
- **Number** → treated as single-item: `"--max-autopilot-continues": 5` → `--max-autopilot-continues 5`
- **Object/null/other** → exit with clear error message before invoking copilot

### Non-`--` keys
- Config keys that do NOT start with `--` are silently ignored (native copilot config fields like `model`, `theme`, `trusted_folders`)

### Error cases
- Missing or unreadable config → proceed silently, invoke copilot with user-supplied args only
- Invalid JSON → exit with clear error message to stderr, do not invoke copilot
- Unsupported value type (object, null, array of non-strings) → exit with clear error to stderr

### Invocation
- Config-injected flags are **prepended** to the argument list; user-supplied args appended after
- Uses `exec` to replace the wrapper process — exit code, stdin, stdout, stderr all transparent
- Config + user args are **additive** (no deduplication)

### Claude's Discretion
- Error message format and prefix (e.g. `copilot-wrapper: error: ...`)
- Whether to check for `jq` availability and emit a helpful message if missing
- Exact quoting strategy for flag values with spaces or special characters

</decisions>

<specifics>
## Specific Ideas

- The `--` prefix convention makes the config file self-documenting: keys look exactly like the flags they inject
- This also means the wrapper is future-proof — any new copilot CLI flag can be used in config immediately without updating the wrapper

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project

### Established Patterns
- None yet — this is the first and only file

### Integration Points
- Real copilot binary at `/home/linuxbrew/.linuxbrew/bin/copilot`
- Config file at `~/.copilot/config.json`
- Script named `copilot` at repo root, intended to shadow real binary via `$PATH` ordering

</code_context>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-working-wrapper*
*Context gathered: 2026-03-03*
