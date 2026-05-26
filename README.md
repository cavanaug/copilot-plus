# copilot-plus

`copilot-plus` is a thin Bash wrapper around the GitHub Copilot CLI.

It exists to make Copilot runs safer and more consistent by auto-applying launch policy, preserving project scope, and exposing inspectable wrapper controls.

If you mainly want the modern Copilot/native split, jump to `Configuration Ownership`.

## Project overview

- Wraps `copilot` and preserves native CLI behavior by default.
- Injects wrapper-managed launch flags automatically from global and project policy.
- Adds wrapper-only operational helpers for visibility and debugging.
- Keeps wrapper options in a separate namespace so upstream flag collisions are avoided.

## Wrapper model and naming

This project is named **copilot-plus** because it is the base tool plus wrapper behavior.

Design rule:

- Native Copilot options stay native.
- Wrapper-only options use `+`/`++` prefixes (for example `++cmd`, `++env`, `++verbose`).

This is a general wrapper pattern: reserve a dedicated option namespace so wrapped-tool flags remain untouched and future-compatible.

## Why this exists

We do not want to maintain this wrapper forever, but broad deprecation is not justified yet.

`copilot-plus` started as a workaround for early Copilot CLI versions that lacked durable settings, repo-local settings, custom instructions, trusted folders, and remembered permissions.

Modern Copilot CLI now provides a substantial native configuration surface:

- `~/.copilot/settings.json`
- `.github/copilot/settings.json`
- `.github/copilot/settings.local.json`
- repository instructions via `copilot init`
- trusted folders and remembered permissions

That closes many of the original gaps, but it does not replace this wrapper completely.

The wrapper is still useful for:

- startup injection of CLI-only launch policy such as `--allow-tool`, `--deny-tool`, `--available-tools`, `--excluded-tools`, `--add-dir`, and `--max-autopilot-continues`
- consistent global + project merge behavior for that policy
- dry-run and inspection helpers such as `++cmd`, `++env`, `++verbose`, and `COPILOT_ARGS`

The main modernization target is separating wrapper policy from upstream-managed Copilot config files more cleanly.

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

## Configuration Ownership

Prefer native Copilot settings whenever there is a documented `settings.json` key. Use wrapper policy only for startup behavior that still exists primarily as CLI flags.

| Prefer native Copilot | Keep wrapper-managed |
| --- | --- |
| `model` | `--allow-tool`, `--deny-tool` |
| `allowedUrls`, `deniedUrls` | `--available-tools`, `--excluded-tools` |
| `trustedFolders` | `--add-dir` |
| `askUser`, `screenReader` | `--max-autopilot-continues` |
| `theme`, `stream`, `logLevel`, `autoUpdate` | `++cmd`, `++env`, `++verbose` |
| native hooks and `.github/copilot/*.json` settings | `COPILOT_ARGS` and global+project launch-policy merge |

Rule of thumb:

- If Copilot documents a native `settings.json` key for a behavior, prefer native config.
- If the behavior is primarily a launch-time CLI flag or wrapper-only inspection feature, keep it in wrapper policy under the nested `copilotPlus` key inside existing Copilot settings files.

## Config Files

### Native Copilot files today

- `~/.copilot/settings.json`
- `.github/copilot/settings.json`
- `.github/copilot/settings.local.json`

### Wrapper files today

- Preferred global wrapper policy host: `~/.copilot/settings.json` under `copilotPlus`
- Preferred shared repo wrapper policy host: `.github/copilot/settings.json` under `copilotPlus`
- Preferred local repo wrapper policy host: `.github/copilot/settings.local.json` under `copilotPlus`
- Legacy fallback paths still honored: `~/.copilot/config.json` and `.copilot/config.json` top-level `--...` keys
- Wrapper input is effectively JSONC: comments and trailing commas are accepted because the script normalizes through `hjson` before `jq`.

Important:

- Modern Copilot treats `~/.copilot/config.json` as managed application state.
- `copilot-plus` now prefers existing Copilot `settings.json` files and only falls back to legacy top-level `--...` entries in `config.json` for compatibility.

### Recommended future wrapper layout

- Global wrapper policy: `~/.copilot/settings.json` under `copilotPlus`
- Shared repo wrapper policy: `.github/copilot/settings.json` under `copilotPlus`
- Local repo wrapper policy: `.github/copilot/settings.local.json` under `copilotPlus`

Rationale:

- extends existing Copilot config files instead of inventing another file
- keeps wrapper-only launch policy namespaced away from native settings
- still avoids normal use of upstream-managed `config.json`

## Runbook

### Prerequisites

- `bash`
- `jq`
- `hjson`
- `envsubst` (usually from `gettext`)
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

Note:

- `++verbose` prints diagnostics and then still executes `copilot`.

### Quick start: modern split

Put native Copilot settings in `~/.copilot/settings.json`:

```jsonc
{
  "model": "gpt-5.4",
  "allowedUrls": ["https://docs.github.com"],
  "trustedFolders": ["/abs/path/to/workspaces"]
}
```

Put wrapper launch policy in the current implementation paths only for behavior that does not have a documented native settings key.

Preferred global wrapper path:

`~/.copilot/settings.json`

```jsonc
{
  "theme": "github-dark-tritanopia",
  "copilotPlus": {
    "--allow-tool": ["shell(git:*)", "write"],
    "--deny-tool": ["shell(git push)"],
    "--max-autopilot-continues": 3
  }
}
```

Preferred shared repo wrapper path:

`.github/copilot/settings.json`

```jsonc
{
  "copilotPlus": {
    "--add-dir": ["./scripts"]
  }
}
```

Preferred local repo override path:

`.github/copilot/settings.local.json`

```jsonc
{
  "copilotPlus": {
    "--model": "gpt-5.4"
  }
}
```

Legacy fallback paths still honored during migration, using top-level `--...` keys:

- `~/.copilot/config.json`
- `.copilot/config.json`

Avoid repeating native settings such as `model`, `allowedUrls`, or `trustedFolders` in wrapper policy.

### Common workflows

Run normally (wrapper injects launch policy automatically):

```bash
copilot "summarize this module"
```

Preview then execute with diagnostics:

```bash
copilot ++cmd "do x"
copilot ++verbose "do x"
```

## Current Wrapper Config Resolution

Current implementation resolves wrapper policy in this order:

1. Preferred global wrapper config: `~/.copilot/settings.json` key `copilotPlus`, else legacy `~/.copilot/config.json`
2. Preferred shared repo wrapper config: nearest parent `.github/copilot/settings.json` key `copilotPlus`, else legacy `.copilot/config.json`
3. Preferred local repo override: nearest parent `.github/copilot/settings.local.json` key `copilotPlus`
3. Auto project scope: injects `--add-dir <PROJECT_ROOT>` when project config root is found

Merge rules:

- Scalar key in both configs: project value overrides global value for that key.
- Array key in both configs: values are additive (global first, project second).
- Type conflict for the same key (array vs scalar): hard error.

Value mapping:

- `array` -> repeated `--key value`
- `true` -> bare `--key`
- `false` -> omitted
- `string`/`number` -> single `--key value`
- `object`/`null`/unsupported -> hard error

Notes:

- Only keys that start with `--` are treated as injectable flags.
- For `--add-dir`, non-existent directories are omitted.
- All string values pass through `envsubst` before injection.
- Avoid adding native Copilot settings here when a documented `settings.json` home exists.

## Recommended Next Layout

The current intended layout is:

1. Global wrapper policy: `~/.copilot/settings.json` key `copilotPlus`
2. Shared repo wrapper policy: nearest parent `.github/copilot/settings.json` key `copilotPlus`
3. Local repo wrapper override: nearest parent `.github/copilot/settings.local.json` key `copilotPlus`
4. Legacy `config.json` paths remain fallback-only compatibility paths
5. Keep the same merge rules, value mapping, and auto-project-root `--add-dir` behavior unless there is an explicit product decision to change them

This preserves the useful startup-policy layer while moving normal use off Copilot's managed `config.json` and onto existing Copilot settings files.

## Wrapper options

- `++cmd` prints the exact command that would run and exits.
- `++env` prints `COPILOT_ARGS` and exits.
- `++verbose` or `+v` prints diagnostics, then executes normally.
- `++help` or `+h` shows wrapper help and exits.
- `++version` or `+V` prints wrapper version and exits.

All non-wrapper arguments are passed through to `copilot` unchanged.

### `COPILOT_ARGS` and recursive calls

`copilot-plus` exports `COPILOT_ARGS` as the shell-quoted, config-derived flags for the current context.

This is intended for nested or subagent invocations of `copilot-plus` so child calls can reuse the same policy without recomputing or dropping arguments.

## Failure modes

- Invalid JSON or JSONC in wrapper config: exits with error before launching `copilot`.
- Unsupported config value type: exits with error.
- Key type conflict between global and project wrapper config: exits with error.
- Missing or unreadable wrapper config files: silent passthrough.

## Tests

Run tests with Bats:

```bash
bats tests/copilot.bats
```

The test suite validates wrapper config parsing, merge behavior, option handling, and execution semantics.

## Reduction Criteria

This wrapper can shrink further or be retired when Copilot CLI natively provides all of the following with documented support:

- persistent config equivalents for startup tool and path policy currently expressed as CLI flags
- per-project launch-policy merge behavior equivalent to this wrapper
- equivalent observability and debuggability for effective runtime args

When those conditions are met, prefer upstream behavior and retire or reduce `copilot-plus`.
