# AGENTS.md

## Repo Shape
- `copilot-plus` is the product: a single Bash wrapper. `tests/copilot.bats` is the main verification surface.
- There is no repo task runner, package manager manifest, or CI workflow here. Do not guess `npm`, `make`, or lint targets.

## Verification
- Canonical verification: `bats tests/copilot.bats`
- Safe manual inspection that does not exec the real Copilot binary: `bash ./copilot-plus ++cmd "prompt"` and `bash ./copilot-plus ++env`
- `++verbose` prints diagnostics and then still `exec`s `copilot`; use it only when a real `copilot` binary is available on `PATH`.

## Runtime Dependencies
- The wrapper currently depends on `bash`, `jq`, `hjson`, `envsubst` (usually from `gettext`), and `copilot` on `PATH`.
- `hjson -c` is part of the real parse path. Config input is effectively JSONC: comments and trailing commas are accepted because the script normalizes through `hjson` before `jq`.

## Config Model
- Preferred global config is `~/.copilot/settings.json` under the `copilotPlus` key; legacy fallback is `~/.copilot/config.json` top-level `--...` keys.
- Preferred project config is the nearest parent `.github/copilot/settings.json` under `copilotPlus`; local override is `.github/copilot/settings.local.json`; legacy fallback is `.copilot/config.json` in the same discovered directory.
- Upward search stops at the first `.copilot/`, at a `.git/` boundary, at `$HOME`, or at `/`. This prevents `~/.copilot` from being mistaken for project config.
- Only top-level keys starting with `--` are injected as flags.
- Project scalars override global scalars for the same key. Array-valued keys are additive. Array/scalar type conflicts are fatal.
- All string values pass through `envsubst` before injection.
- `--add-dir` entries are skipped if the target directory does not exist.
- When project config is found, the wrapper also auto-injects `--add-dir <project-root>`.
- Modern Copilot uses `~/.copilot/settings.json` for user settings; extend existing settings files via a nested `copilotPlus` key rather than inventing another file.

## Bash And Test Gotchas
- `COPILOT_ARGS` contains only config-derived flags, shell-quoted. User-supplied args are intentionally excluded so nested calls can reuse policy without replaying prompt args.
- If you touch control flow in `copilot-plus`, prefer explicit `if` blocks over `&&`/`||` chains inside loops/functions; this repo already hit `set -e` edge cases there.
- When testing project-config discovery, change the real cwd with `cd`. Setting `PWD` in the environment does not change Bash's `$PWD`.
