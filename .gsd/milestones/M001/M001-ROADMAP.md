# M001: Migration

**Vision:** A bash wrapper script for the GitHub Copilot CLI that reads global and per-project Copilot config, injects matching CLI flags automatically, and preserves transparent invocation behavior.

## Success Criteria

- Users can invoke the wrapper normally and have config-derived CLI flags injected automatically from supported config sources.
- Global and per-project config behavior is verified by automated tests, including merge semantics and failure cases.
- Nested invocations can preserve config-derived launch context through exported `COPILOT_ARGS`.

## Slices

- [x] **S01: Working Wrapper** `risk:medium` `depends:[]`
  > After this: Build and test the complete `copilot` bash wrapper script using TDD.
- [x] **S02: Per Project Config File Support** `risk:medium` `depends:[S01]`
  > After this: Extend the `copilot-cli` wrapper with per-project config support and `COPILOT_ARGS` export using TDD.
