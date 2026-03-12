# copilot-cli-wrapper

## What This Is

A bash wrapper for the GitHub Copilot CLI that reads Copilot config, translates supported config entries into CLI flags, and launches the real Copilot binary with those flags injected automatically.

## Current State

The project has completed its initial delivery milestone. The wrapper behavior captured in this repository includes:
- global config reading from `~/.copilot/config.json`
- per-project config reading from `$PWD/.copilot/config.json`
- additive merge with key-level override when both config sources define the same `--` key
- exported `COPILOT_ARGS` for nested invocations that need to preserve config-derived launch context
- automated verification via bats tests and smoke-tested wrapper behavior

## Core Value

Users can define supported Copilot CLI flags in config once and have them injected automatically on every invocation instead of retyping them manually.

## Requirements Snapshot

### Validated

- Read Copilot config at invocation time and inject supported `--`-prefixed keys as CLI flags.
- Expand array values into repeated flag/value pairs.
- Support boolean, string, and number flag values with explicit failure on unsupported types.
- Preserve transparent wrapper behavior by prepending config-derived flags and exec-ing the real Copilot binary.
- Merge global and per-project config with project-level override semantics.
- Export `COPILOT_ARGS` containing only config-derived flags for nested wrapper usage.

### Active

(None currently — migration shows the known scoped work as complete.)

### Out of Scope

- Interactive config selection UI
- Named profiles or multiple arbitrary config sources
- Broader non-wrapper Copilot CLI feature work
- Reimplementation in another language

## Context

The official Copilot CLI accepts many flags directly but does not natively use all desired config-driven invocation patterns. This project bridges that gap with a bash-first wrapper that keeps normal CLI usage intact while making config-driven behavior automatic.

## Constraints

- **Tech stack:** Bash with `jq` for JSON parsing
- **Runtime model:** Wrapper must preserve transparent CLI behavior
- **Scope boundary:** Config-to-flags translation and invocation ergonomics only

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bash over Python/Node | Keep the wrapper portable and dependency-light | Adopted |
| `jq` for parsing | Reliable JSON parsing in shell context | Adopted |
| General-purpose `--` key convention | Avoid hardcoded flag tables where possible | Adopted |
| Per-project config with key-level override | Preserve global defaults while allowing project specialization | Adopted |
| Export `COPILOT_ARGS` | Preserve config-derived context for nested invocations | Adopted |

---
*Last updated: 2026-03-12 during migration stabilization checkpoint*
