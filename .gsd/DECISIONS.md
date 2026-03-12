# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| 1 | 2026-03-04 | wrapper-exec | Real Copilot binary resolution for tests | Use `COPILOT_REAL_BINARY` env override while keeping the production default path | Absolute-path exec bypasses PATH-based test stubs; env override preserves production behavior and enables reliable tests | yes |
| 2 | 2026-03-04 | config-dispatch | Config value type handling | Dispatch `array`, `boolean`, `string`, and `number` into flags; reject `object` and `null` with an error | Keeps wrapper behavior general-purpose while failing clearly on unsupported config shapes | yes |
| 3 | 2026-03-04 | config-merge | Global vs project config precedence | Use two-pass processing so project keys override global keys cleanly | Produces additive merge for different keys and deterministic override for shared keys without complex state | yes |
| 4 | 2026-03-04 | bash-implementation | Passing mutable arrays into helpers | Use bash nameref (`local -n`) in `read_config_flags` | Avoids global-variable collision between global and project config passes | yes |
| 5 | 2026-03-04 | bash-safety | Boolean checks inside loops under `set -e` | Use explicit `if/then` instead of `&&` short-circuit checks | Prevents false-condition exit codes from propagating unexpectedly in bash 5.2 | yes |
| 6 | 2026-03-04 | test-harness | Project-config test working directory | Change real working directory with `cd` instead of relying on injected `PWD` | Bash computes `$PWD` from the actual cwd, not the env var, so project config lookup needs a real directory change | yes |
| 7 | 2026-03-04 | nested-invocation | Empty `COPILOT_ARGS` handling | Guard empty arrays explicitly before `printf '%q '` | Prevents quoted-empty-string output when no config-derived flags exist | yes |
