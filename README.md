# copilot-plus

`copilot-plus` is a thin Bash wrapper around the GitHub Copilot CLI.

It exists to make Copilot runs safer and more consistent by auto-applying config-derived flags, preserving project scope, and exposing inspectable wrapper controls.

If you mainly want to set config keys fast, jump to `Quick start: config by example`.

## Project overview

- Wraps `copilot` and preserves native CLI behavior by default.
- Injects config-derived flags automatically from global and project config.
- Adds wrapper-only operational helpers for visibility and debugging.
- Keeps wrapper options in a separate namespace so upstream flag collisions are avoided.

## Wrapper model and naming

This project is named **copilot-plus** because it is the base tool plus wrapper behavior.

Design rule:

- Native Copilot options stay native.
- Wrapper-only options use `+`/`++` prefixes (for example `++cmd`, `++env`, `++verbose`).

This is a general wrapper pattern: reserve a dedicated option namespace so wrapped-tool flags remain untouched and future-compatible.

## Why this exists

We do not want to maintain this wrapper forever.

`copilot-plus` exists because current Copilot CLI behavior is not sufficient for this workflow:

- Global and per-project config handling is not ergonomic enough for daily use.
- Repeating permission/context flags on every invocation is error-prone.
- Team consistency drifts when each engineer runs different ad hoc launch args.

Preferred future state: remove this project once Copilot CLI natively supports the same workflow with equivalent safety and consistency.

## Safety stance

- YOLO-style defaults (minimal or no permission controls) are not acceptable for shared environments.
- Permissive-by-default automation is convenient short term but creates avoidable risk and cleanup cost.
- `copilot-plus` makes the safer path the default: explicit allow/deny controls, project scoping, and auditable effective args.

## Agent security model

Security failures here are usually workflow failures first.

- Too many approval prompts create approval fatigue.
- Approval fatigue pushes people toward broad allow-lists or YOLO mode to reduce interruption.
- YOLO mode removes meaningful guardrails exactly when they are needed most.

Our policy is a deliberate middle ground:

- Keep enough permission friction to prevent dangerous defaults.
- Reduce repetitive approvals by codifying stable allow/deny policy in config.
- Keep runtime behavior auditable with `++cmd`, `++env`, and `++verbose`.

This is neither maximum lock-down nor run wild. It is controlled autonomy with explicit boundaries.

### Future direction: OS-level sandboxing

A possible future enhancement is to run Copilot inside a Linux sandbox wrapper (for example, a tool like `fence`) to enforce filesystem isolation at the OS boundary.

Possible goals:

- Explicitly deny agent access to sensitive directories by default.
- Prevent access to credential material such as `~/.aws`, `~/.ssh`, and `~/.gnupg` unless intentionally allowed.
- Add a defense layer that does not depend only on in-tool permission semantics.

This is future work, not part of the current implementation.

## Runbook

### Prerequisites

- `bash`
- `jq`
- `copilot` on `PATH`

### Install

```bash
chmod +x ./copilot-plus
```

Add an alias in shell config:

```bash
alias copilot='copilot-plus'
```

Reload shell.

### First verification

Show wrapper help:

```bash
copilot ++help
```

Preview final command without executing:

```bash
copilot ++cmd "test prompt"
```

Show computed config args only:

```bash
copilot ++env
```

### Quick start: config by example

Create global config:

```bash
mkdir -p ~/.copilot
```

`~/.copilot/config.json`

```json
{
  "--model": "gpt-5",
  "--allow-tool": ["bash", "read", "write"],
  "--yolo": false,
  "--max-autopilot-continues": 3
}
```

Add project-specific overrides in your repo:

```bash
mkdir -p .copilot
```

`.copilot/config.json`

```json
{
  "--model": "gpt-5-codex",
  "--allow-tool": ["shell(git:*)"],
  "--add-dir": ["$HOME/.copilot/tools", "./scripts"]
}
```

What this does in practice:

- `--model` (scalar): project value overrides global value.
- `--allow-tool` (array): project values are added after global values.
- `--yolo: false`: omitted entirely.
- `--add-dir`: each value becomes another `--add-dir <path>`; missing directories are skipped.
- `$HOME` and other env vars inside string values are expanded.

Check exactly what will be used:

```bash
copilot ++env
copilot ++cmd "explain this file"
```

Rule of thumb for adding keys:

- Key must start with `--` (otherwise ignored).
- Value can be `string`, `number`, `boolean`, or `array`.
- `object` and `null` values are rejected with an error.

### Common workflows

Run normally (wrapper injects config flags automatically):

```bash
copilot "summarize this module"
```

Preview then execute with diagnostics:

```bash
copilot ++cmd "do x"
copilot ++verbose "do x"
```

## Config resolution model

`copilot-plus` resolves config in this order:

1. Global config: `~/.copilot/config.json`
2. Project config: nearest parent `.copilot/config.json` found by walking upward from current directory
3. Auto project scope: injects `--add-dir <PROJECT_ROOT>` when project config root is found

Merge rules:

- Scalar key in both configs: project value overrides global value for that key.
- Array key in both configs: values are additive (global first, project second).
- Type conflict for same key (array vs scalar): hard error.

Value mapping:

- `array` -> repeated `--key value`
- `true` -> bare `--key`
- `false` -> omitted
- `string`/`number` -> single `--key value`
- `object`/`null`/unsupported -> hard error

Notes:

- Only keys that start with `--` are treated as injectable flags.
- For `--add-dir`, non-existent directories are omitted.

## Wrapper options

- `++cmd` prints the exact command that would run and exits.
- `++env` prints `COPILOT_ARGS` and exits.
- `++verbose` or `+v` prints diagnostics, then executes normally.
- `++help` or `+h` shows wrapper help and exits.
- `++version` or `+V` prints wrapper version and exits.

All non-wrapper arguments are passed through to `copilot` unchanged.

### `COPILOT_ARGS` and recursive calls

`copilot-plus` exports `COPILOT_ARGS` as the shell-quoted, config-derived flags for the current context.

This is intended for nested/subagent invocations of `copilot-plus` so child calls can reuse the same policy without recomputing or dropping arguments.

In other words, it supports recursive invocation patterns while preserving the same effective config boundaries.

## Failure modes

- Invalid JSON in config: exits with error before launching `copilot`.
- Unsupported config value type: exits with error.
- Key type conflict between global and project config: exits with error.
- Missing/unreadable config files: silent passthrough.

## Tests

Run tests with Bats:

```bash
bats tests/copilot.bats
```

The test suite validates config parsing, merge behavior, option handling, and execution semantics.

## Deprecation criteria

This wrapper should be removed when Copilot CLI can natively provide:

- Reliable global + project config behavior.
- Safe permission defaults suitable for real-world use.
- Equivalent observability/debuggability for effective runtime args.

When those conditions are met, prefer upstream behavior and retire `copilot-plus`.
