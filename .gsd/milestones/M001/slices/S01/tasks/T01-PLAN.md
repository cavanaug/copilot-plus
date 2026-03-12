# T01: 01-working-wrapper 01

**Slice:** S01 — **Milestone:** M001

## Description

Build and test the complete `copilot` bash wrapper script using TDD.

Purpose: Deliver the entire phase-1 deliverable — a single bash script that reads `~/.copilot/config.json`, finds all keys starting with `--`, maps their values to CLI flags using a general-purpose type-dispatch mechanism, prepends them to user args, and exec-replaces itself with the real copilot binary.

Output:
- `copilot` — the executable wrapper script (placed in repo root; user copies it earlier in $PATH)
- `tests/copilot.bats` — full bats test suite proving all 16 requirements pass

## Must-Haves

- [ ] "Running `copilot myarg` with `\"--add-dir\": [\"/tmp\"]` in config causes `--add-dir /tmp myarg` to reach the real copilot"
- [ ] "Running `copilot myarg` with `\"--yolo\": true` in config causes `--yolo myarg` to reach the real copilot"
- [ ] "Running `copilot myarg` with `\"--yolo\": false` in config skips that flag — only `myarg` reaches the real copilot"
- [ ] "Running `copilot myarg` with `\"--model\": \"gpt-4.1\"` in config causes `--model gpt-4.1 myarg` to reach real copilot"
- [ ] "Running `copilot myarg` with no config file proceeds silently — real copilot gets only `myarg`"
- [ ] "Running `copilot myarg` with malformed JSON config exits non-zero with an error to stderr, never calls real copilot"
- [ ] "Running `copilot myarg` with an object value like `\"--bad\": {}` exits non-zero with an error to stderr, never calls real copilot"
- [ ] "Config keys NOT starting with `--` (e.g. `\"model\": \"gpt-4.1\"`) are silently ignored"
- [ ] "Config-injected flags are prepended; user args come after — order is preserved"
- [ ] "Config flags and user-supplied flags of the same type are both present in the final invocation (additive)"
- [ ] "Wrapper uses exec — the wrapper process is replaced, not a subprocess"

## Files

- `copilot`
- `tests/copilot.bats`
