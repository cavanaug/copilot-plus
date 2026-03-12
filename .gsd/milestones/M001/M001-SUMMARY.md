---
id: M001
provides:
  - "Bash Copilot wrapper with automated config-to-CLI flag injection"
  - "Per-project config merge with key-level override and exported COPILOT_ARGS"
key_decisions:
  - "Use COPILOT_REAL_BINARY env override for test isolation without changing production exec behavior"
  - "Use two-pass config processing so project keys override global keys cleanly"
patterns_established:
  - "Bats-based TDD for wrapper behavior and config merge semantics"
  - "Shell-quoted COPILOT_ARGS export for nested invocation context preservation"
observability_surfaces:
  - "bats tests/copilot.bats"
requirement_outcomes:
  - id: CONF-01
    from_status: active
    to_status: validated
    proof: "Covered by passing wrapper tests and slice S01 summary evidence"
  - id: CONF-02
    from_status: active
    to_status: validated
    proof: "Covered by missing/unreadable config tests in slice S01"
  - id: CONF-03
    from_status: active
    to_status: validated
    proof: "Covered by invalid JSON failure tests in slice S01"
  - id: MAP-01
    from_status: active
    to_status: validated
    proof: "Covered by general-purpose -- key dispatch tests in slice S01"
  - id: MAP-02
    from_status: active
    to_status: validated
    proof: "Covered by array expansion tests in slice S01"
  - id: MAP-03
    from_status: active
    to_status: validated
    proof: "Covered by boolean true injection tests in slice S01"
  - id: MAP-04
    from_status: active
    to_status: validated
    proof: "Covered by boolean false skip tests in slice S01"
  - id: MAP-05
    from_status: active
    to_status: validated
    proof: "Covered by string and number value tests in slice S01"
  - id: MAP-06
    from_status: active
    to_status: validated
    proof: "Covered by unsupported object/null value tests in slice S01"
  - id: MAP-07
    from_status: active
    to_status: validated
    proof: "Covered by non---prefixed key ignore tests in slice S01"
  - id: INVK-01
    from_status: active
    to_status: validated
    proof: "Covered by prepended config flag ordering tests in slice S01"
  - id: INVK-02
    from_status: active
    to_status: validated
    proof: "Covered by additive invocation tests in slice S01"
  - id: INVK-03
    from_status: active
    to_status: validated
    proof: "Covered by exec behavior verification in slice S01"
  - id: INVK-04
    from_status: active
    to_status: validated
    proof: "Covered by transparent wrapper behavior tests in slice S01"
  - id: DIST-01
    from_status: active
    to_status: validated
    proof: "Delivered as a single bash wrapper with jq dependency documented and tested"
  - id: DIST-02
    from_status: active
    to_status: validated
    proof: "Validated in slice S01 with script naming and invocation behavior evidence"
duration: migrated
verification_result: passed
completed_at: 2026-03-04
---

# M001: copilot-cli-wrapper

**Bash Copilot wrapper delivery completed through two slices: core config-to-flag injection first, then per-project config merge and nested invocation context export.**

## What Happened

The migrated milestone captures a complete wrapper implementation history. S01 established the core wrapper behavior: reading config, dispatching supported JSON value types into CLI flags, preserving transparent invocation semantics, and validating everything through bats-based TDD and smoke checks. S02 extended that working base to support per-project `.copilot/config.json`, additive merge with key-level override, and `COPILOT_ARGS` export so nested invocations can preserve launch context. Together the slices represent a coherent completed milestone rather than partial scaffolding.

## Cross-Slice Verification

- Contract verification: automated `bats tests/copilot.bats` coverage documented in slice summaries, growing from 18 passing tests in S01 to 32 passing tests in S02.
- Integration verification: smoke tests against the real Copilot binary are documented in both slice summaries.
- Operational verification: wrapper behavior preserves direct exec semantics and transparent passthrough, including error handling and config absence behavior.

## Requirement Changes

- CONF-01: active → validated — wrapper reads global config at invocation time.
- CONF-02: active → validated — missing or unreadable config silently falls back to passthrough.
- CONF-03: active → validated — invalid JSON fails before invoking Copilot.
- MAP-01: active → validated — `--`-prefixed config keys are treated as injectable flags.
- MAP-02: active → validated — array values expand to repeated flag/value pairs.
- MAP-03: active → validated — boolean true injects a bare flag.
- MAP-04: active → validated — boolean false skips injection.
- MAP-05: active → validated — string and number values inject as single flag/value pairs.
- MAP-06: active → validated — unsupported object/null values fail clearly.
- MAP-07: active → validated — non-flag keys are ignored.
- INVK-01: active → validated — config-derived flags are prepended ahead of user args.
- INVK-02: active → validated — config and user flags are additive.
- INVK-03: active → validated — wrapper execs the real Copilot binary.
- INVK-04: active → validated — wrapper remains transparent in exit code and stdio behavior.
- DIST-01: active → validated — delivery is a self-contained bash wrapper with jq-based parsing.
- DIST-02: active → validated — naming and invocation model were preserved for intended alias-based use.

## Forward Intelligence

### What the next milestone should know
- The migrated slice summaries already capture the most important implementation decisions; read them before extending wrapper behavior.
- The meaningful proof surface for this project is the bats suite plus targeted smoke tests, not just artifact existence.

### What's fragile
- Shell quoting and `set -e` behavior remain the subtle edge cases in this codebase — future bash changes should be test-first.
- Project-vs-global config behavior depends on ordering and exact merge semantics, so changes here should preserve current test coverage expectations.

### Authoritative diagnostics
- `tests/copilot.bats` — this is the highest-signal verification surface for wrapper behavior.
- Slice summaries `S01-SUMMARY.md` and `S02-SUMMARY.md` — these contain the real migration intelligence and bug-fix rationale.

### What assumptions changed
- Initial planning assumed hardcoded exec path and PATH-stub testing would coexist cleanly; actual implementation required `COPILOT_REAL_BINARY` override for testability.
- Initial planning also assumed injected `PWD` env vars were sufficient for project-config tests; actual validation required changing real working directory.

## Files Created/Modified

- `.gsd/milestones/M001/M001-ROADMAP.md` — migrated milestone roadmap with completed slices.
- `.gsd/milestones/M001/slices/S01/S01-PLAN.md` — migrated slice plan for the working wrapper.
- `.gsd/milestones/M001/slices/S01/S01-SUMMARY.md` — migrated slice summary with proof and decisions.
- `.gsd/milestones/M001/slices/S02/S02-PLAN.md` — migrated slice plan for per-project config support.
- `.gsd/milestones/M001/slices/S02/S02-SUMMARY.md` — migrated slice summary with merge and `COPILOT_ARGS` details.
