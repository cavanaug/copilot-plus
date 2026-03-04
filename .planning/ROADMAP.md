# Roadmap: copilot-cli-wrapper

## Overview

A single-phase delivery: build a self-contained bash wrapper script that reads `~/.copilot/config.json`, maps array fields to their CLI flag equivalents, and transparently exec-replaces the real `copilot` binary with the expanded flags injected. All 16 v1 requirements belong to one coherent deliverable — the working wrapper script.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Working Wrapper** - Complete bash wrapper that reads config, maps array fields to flags, and transparently invokes copilot

## Phase Details

### Phase 1: Working Wrapper
**Goal**: Users can drop a single bash script named `copilot` earlier in `$PATH` and have all array fields from `~/.copilot/config.json` automatically injected as CLI flags on every invocation — with no change to their normal copilot usage
**Depends on**: Nothing (first phase)
**Requirements**: CONF-01, CONF-02, CONF-03, MAP-01, MAP-02, MAP-03, MAP-04, MAP-05, MAP-06, MAP-07, INVK-01, INVK-02, INVK-03, INVK-04, DIST-01, DIST-02
**Success Criteria** (what must be TRUE):
  1. Running `copilot <args>` with a valid config containing `allowed_dirs`, `allowed_tools`, `denied_tools`, `allowed_urls`, or `denied_urls` arrays causes each array element to be passed as its corresponding flag to the real copilot binary
  2. Running `copilot <args>` when `~/.copilot/config.json` is absent or unreadable behaves identically to calling the real copilot directly — no error, no missing args
  3. Running `copilot <args>` when the config exists but contains invalid JSON exits immediately with a clear error message before invoking copilot
  4. User-supplied flags of the same type as config-injected flags are both applied (additive, not override); all other user-supplied args pass through unchanged
  5. The wrapper `exec`s the real copilot binary — exit code, stdin, stdout, and stderr are indistinguishable from calling copilot directly
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Working Wrapper | 0/? | Not started | - |
