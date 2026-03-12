# S01: Working Wrapper

**Goal:** Build and test the complete `copilot` bash wrapper script using TDD.
**Demo:** Build and test the complete `copilot` bash wrapper script using TDD.

## Must-Haves


## Tasks

- [x] **T01: 01-working-wrapper 01** `est:4min`
  - Build and test the complete `copilot` bash wrapper script using TDD.

Purpose: Deliver the entire phase-1 deliverable — a single bash script that reads `~/.copilot/config.json`, finds all keys starting with `--`, maps their values to CLI flags using a general-purpose type-dispatch mechanism, prepends them to user args, and exec-replaces itself with the real copilot binary.

Output:
- `copilot` — the executable wrapper script (placed in repo root; user copies it earlier in $PATH)
- `tests/copilot.bats` — full bats test suite proving all 16 requirements pass

## Files Likely Touched

- `copilot`
- `tests/copilot.bats`
