# Requirements

This file is the explicit capability and coverage contract for the project.

## Active

(None)

## Validated

### CONF-01 — Wrapper reads `~/.copilot/config.json` at invocation time
- Class: core-capability
- Status: validated
- Description: The wrapper reads the global Copilot config file each time it is invoked.
- Why it matters: Users can manage persistent wrapper behavior through config instead of repeating flags manually.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Covered by the passing S01 bats suite and documented smoke testing.

### CONF-02 — Missing or unreadable global config falls back to silent passthrough
- Class: failure-visibility
- Status: validated
- Description: If the global config file is missing or unreadable, the wrapper invokes Copilot with only user-supplied args and no extra error noise.
- Why it matters: The wrapper remains transparent and safe in normal shell environments.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by missing/unreadable config tests in the S01 verification suite.

### CONF-03 — Invalid global config JSON fails before Copilot is invoked
- Class: failure-visibility
- Status: validated
- Description: If the global config file exists but contains invalid JSON, the wrapper exits with a clear error before invoking Copilot.
- Why it matters: Prevents silent misuse and gives a debuggable failure mode.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by invalid JSON test coverage in S01.

### MAP-01 — `--`-prefixed config keys are treated as injectable CLI flags
- Class: core-capability
- Status: validated
- Description: Any supported top-level config key beginning with `--` is interpreted as a wrapper-injectable CLI flag.
- Why it matters: Avoids hardcoded mappings and keeps the wrapper broadly useful.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by general-purpose key-dispatch tests in S01.

### MAP-02 — Array values expand to repeated flag/value pairs
- Class: core-capability
- Status: validated
- Description: Array-valued config entries emit one flag/value pair per element.
- Why it matters: Supports the primary use case of storing repeated CLI flags in config.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by array expansion tests in S01.

### MAP-03 — Boolean true injects a bare flag
- Class: core-capability
- Status: validated
- Description: Boolean `true` config values inject the corresponding flag without a following value.
- Why it matters: Supports toggle-style Copilot CLI options.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by boolean true tests in S01.

### MAP-04 — Boolean false skips injection
- Class: core-capability
- Status: validated
- Description: Boolean `false` config values cause the corresponding flag to be omitted entirely.
- Why it matters: Prevents false-valued config from turning into incorrect CLI arguments.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by boolean false tests in S01.

### MAP-05 — String and number values inject as single flag/value pairs
- Class: core-capability
- Status: validated
- Description: Scalar string and number config values inject a single flag/value pair.
- Why it matters: Supports model selection and similar single-value CLI options.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by string and number tests in S01.

### MAP-06 — Unsupported object and null values fail clearly
- Class: failure-visibility
- Status: validated
- Description: Object, null, and other unsupported value types cause the wrapper to exit with a clear error before invoking Copilot.
- Why it matters: Keeps failure behavior explicit and prevents malformed config from producing undefined CLI behavior.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by unsupported-type tests in S01.

### MAP-07 — Non-flag config keys are ignored by the wrapper
- Class: constraint
- Status: validated
- Description: Config keys that do not start with `--` are ignored for wrapper injection.
- Why it matters: Preserves compatibility with native Copilot config fields and avoids accidental translation.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by ignore-behavior tests in S01.

### INVK-01 — Config-derived flags are prepended ahead of user args
- Class: integration
- Status: validated
- Description: The wrapper prepends config-derived flags before the user-supplied argument list.
- Why it matters: Preserves deterministic invocation order and matches the wrapper contract.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by ordering tests in S01.

### INVK-02 — Config-derived and user-supplied flags are additive
- Class: integration
- Status: validated
- Description: When config-derived and user-supplied flags overlap, both sets are present in the final Copilot invocation.
- Why it matters: Prevents wrapper behavior from silently discarding explicit user input.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by additive invocation tests in S01.

### INVK-03 — Wrapper execs the real Copilot binary
- Class: operability
- Status: validated
- Description: The wrapper replaces itself with the real Copilot process instead of spawning a buffered subprocess wrapper.
- Why it matters: Preserves normal process behavior, exit codes, and terminal interaction.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified in S01 via exec-focused behavior tests and smoke checks.

### INVK-04 — Wrapper remains transparent in exit code and stdio behavior
- Class: operability
- Status: validated
- Description: The wrapper behaves like direct Copilot invocation for stdin, stdout, stderr, and exit codes.
- Why it matters: Users can adopt the wrapper without changing normal CLI workflows.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Verified by S01 tests and smoke checks.

### DIST-01 — Delivery is a self-contained bash wrapper using `jq`
- Class: constraint
- Status: validated
- Description: The wrapper is implemented as a single bash script with runtime dependency on `jq` and the real Copilot binary.
- Why it matters: Keeps installation and portability simple.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Reflected in delivered artifacts and S01 summary evidence.

### DIST-02 — Intended invocation model is `copilot-plus` via shell aliasing
- Class: constraint
- Status: validated
- Description: The script is intended to be named `copilot-plus` and used via aliasing so user `copilot` invocations route through the wrapper while the script still resolves the real binary correctly.
- Why it matters: Preserves a clean user-facing CLI experience without recursive self-invocation.
- Source: inferred
- Primary owning slice: M001/S01
- Supporting slices: none
- Validation: validated
- Notes: Documented in project context and validated during the original implementation history.

## Deferred

(None)

## Out of Scope

(None formalized in migrated GSD requirements; see PROJECT.md for current scope boundaries.)

## Traceability

| ID | Class | Status | Primary owner | Supporting | Proof |
|---|---|---|---|---|---|
| CONF-01 | core-capability | validated | M001/S01 | none | validated |
| CONF-02 | failure-visibility | validated | M001/S01 | none | validated |
| CONF-03 | failure-visibility | validated | M001/S01 | none | validated |
| MAP-01 | core-capability | validated | M001/S01 | none | validated |
| MAP-02 | core-capability | validated | M001/S01 | none | validated |
| MAP-03 | core-capability | validated | M001/S01 | none | validated |
| MAP-04 | core-capability | validated | M001/S01 | none | validated |
| MAP-05 | core-capability | validated | M001/S01 | none | validated |
| MAP-06 | failure-visibility | validated | M001/S01 | none | validated |
| MAP-07 | constraint | validated | M001/S01 | none | validated |
| INVK-01 | integration | validated | M001/S01 | none | validated |
| INVK-02 | integration | validated | M001/S01 | none | validated |
| INVK-03 | operability | validated | M001/S01 | none | validated |
| INVK-04 | operability | validated | M001/S01 | none | validated |
| DIST-01 | constraint | validated | M001/S01 | none | validated |
| DIST-02 | constraint | validated | M001/S01 | none | validated |

## Coverage Summary

- Active requirements: 0
- Mapped to slices: 16
- Validated: 16
- Unmapped active requirements: 0
