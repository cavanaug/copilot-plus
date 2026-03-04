# Requirements: copilot-cli-wrapper

**Defined:** 2026-03-03
**Core Value:** Any `allowed_*` / `denied_*` array in `~/.copilot/config.json` is automatically expanded into CLI flags on every copilot invocation — zero extra typing required.

## v1 Requirements

### Config Reading

- [ ] **CONF-01**: Wrapper reads `~/.copilot/config.json` at invocation time
- [ ] **CONF-02**: If config file is missing or unreadable, wrapper proceeds silently (no error) and invokes copilot with only the user-supplied args
- [ ] **CONF-03**: If config file exists but is not valid JSON, wrapper exits with a clear error message before invoking copilot

### Field Mapping

- [ ] **MAP-01**: `allowed_dirs` array → one `--add-dir <value>` flag per item
- [ ] **MAP-02**: `allowed_tools` array → one `--allow-tool <value>` flag per item
- [ ] **MAP-03**: `denied_tools` array → one `--deny-tool <value>` flag per item
- [ ] **MAP-04**: `allowed_urls` array → one `--allow-url <value>` flag per item
- [ ] **MAP-05**: `denied_urls` array → one `--deny-url <value>` flag per item
- [ ] **MAP-06**: Config keys not in the mapping table are silently ignored
- [ ] **MAP-07**: Non-array values for mapped keys cause the wrapper to exit with a clear error message before invoking copilot

### Invocation

- [ ] **INVK-01**: Config-injected flags are prepended to the argument list; all user-supplied args are passed through unchanged and appended after
- [ ] **INVK-02**: Config-injected flags and user-supplied flags of the same type are both applied (additive, not override)
- [ ] **INVK-03**: Wrapper execs the real `copilot` binary — process replaces the wrapper (no subprocess, no output buffering)
- [ ] **INVK-04**: Wrapper is transparent: exit code, stdin, stdout, stderr all behave as if the user called copilot directly

### Distribution

- [ ] **DIST-01**: Wrapper is a single self-contained bash script with no runtime dependencies beyond `jq` (for JSON parsing) and the `copilot` binary
- [ ] **DIST-02**: Script is named `copilot` and intended to be placed earlier in `$PATH` than the real copilot binary, shadowing it

## v2 Requirements

### Extended Config

- **EXT-01**: Per-project config (e.g. `.copilot/config.json`) that merges with the global config
- **EXT-02**: Configurable config path via `COPILOT_WRAPPER_CONFIG` env var
- **EXT-03**: Support for scalar config fields that map to single-value CLI flags (e.g. `model` → `--model`)

### Ergonomics

- **ERG-01**: `--wrapper-debug` flag that prints the full constructed command before exec-ing (for troubleshooting)
- **ERG-02**: Support for `available_tools` array → `--available-tools` (space-separated variant)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Interactive config picker | User wants silent auto-injection, not UI |
| Named profiles | Single config file only for v1 |
| Broader CLI ergonomics | Flags translation only |
| Languages other than bash | Portability requirement |
| Trusting `trusted_folders` natively | That field is project-scoped, handled differently |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CONF-01 | Phase 1 | Pending |
| CONF-02 | Phase 1 | Pending |
| CONF-03 | Phase 1 | Pending |
| MAP-01 | Phase 1 | Pending |
| MAP-02 | Phase 1 | Pending |
| MAP-03 | Phase 1 | Pending |
| MAP-04 | Phase 1 | Pending |
| MAP-05 | Phase 1 | Pending |
| MAP-06 | Phase 1 | Pending |
| MAP-07 | Phase 1 | Pending |
| INVK-01 | Phase 1 | Pending |
| INVK-02 | Phase 1 | Pending |
| INVK-03 | Phase 1 | Pending |
| INVK-04 | Phase 1 | Pending |
| DIST-01 | Phase 1 | Pending |
| DIST-02 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-03*
*Last updated: 2026-03-03 after roadmap creation*
