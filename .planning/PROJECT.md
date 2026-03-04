# copilot-cli-wrapper

## What This Is

A bash wrapper script for the GitHub Copilot CLI that reads `~/.copilot/config.json` and auto-injects array-based config fields as their corresponding CLI flags. Users who have defined `allowed_paths`, `allowed_tools`, `denied_paths`, `denied_tools`, and similar list fields in their config file no longer need to spell out `--allow-path /foo --allow-path /bar` on every invocation — the wrapper handles it transparently.

## Core Value

Any array-based config field in `~/.copilot/config.json` that has a CLI flag equivalent is automatically expanded and injected when launching the Copilot CLI — zero extra typing, no missed entries.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Read `~/.copilot/config.json` at invocation time
- [ ] Discover all array fields that follow the established naming convention (e.g. `allowed_paths` → `--allow-path`, `denied_tools` → `--deny-tool`)
- [ ] Expand each array element into its own flag and inject into the Copilot CLI invocation
- [ ] Pass all other CLI arguments through to the underlying Copilot CLI unchanged
- [ ] Behave transparently — user experience is identical to calling `copilot` directly, just with config respected

### Out of Scope

- Interactive config picker — user wants simple auto-injection, not a UI
- Named profiles / multiple config sources — single fixed config file only
- Broader CLI ergonomics — flags only, not a general Copilot CLI enhancement
- Languages other than bash — keep it simple and portable

## Context

- The official Copilot CLI supports `--allow-path`, `--deny-path`, `--allow-tool`, `--deny-tool` (and likely similar) flags but does not read the corresponding array fields from `~/.copilot/config.json`
- The user has already established a clear naming convention in their config: past-tense verb + plural noun (e.g. `allowed_paths`, `denied_tools`) maps to present-tense verb + singular noun CLI flag (e.g. `--allow-path`, `--deny-tool`)
- The wrapper should detect all such mappable array fields automatically rather than hardcoding a fixed list

## Constraints

- **Tech stack**: Bash — no runtime dependencies, must work anywhere the Copilot CLI runs
- **Config source**: Fixed at `~/.copilot/config.json` — no overrides or merging
- **Scope**: Config-to-flags translation only — not a general-purpose CLI wrapper framework

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Bash over Python/Node | Simple, portable, no extra dependencies | — Pending |
| Fixed config path | User wants simplicity, not flexibility | — Pending |
| Auto-discover field mappings via naming convention | Covers all current and future list fields without hardcoding | — Pending |

---
*Last updated: 2026-03-03 after initialization*
