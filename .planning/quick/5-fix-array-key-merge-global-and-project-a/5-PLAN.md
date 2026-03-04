---
phase: quick-5
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus
  - tests/copilot.bats
autonomous: true
requirements: []

must_haves:
  truths:
    - "Array keys (--add-dir, --allow-tool) from both global AND project config are all passed to copilot"
    - "Scalar keys (--model, --yolo) from project config replace the global value entirely"
    - "EXT-01g/h tests pass using a scalar key for override"
    - "New additive-array tests pass confirming global + project values both appear"
  artifacts:
    - path: "copilot-plus"
      provides: "Fixed project_keys skip-map (scalar-only)"
    - path: "tests/copilot.bats"
      provides: "Updated EXT-01g/h (scalar key) + new EXT-01k/l (array additive)"
  key_links:
    - from: "copilot-plus lines 104-106"
      to: "project_keys skip map"
      via: "jq type filter — only non-array keys enter skip map"
      pattern: "jq.*type.*array"
---

<objective>
Fix the config merge logic so array-typed keys are additive (global + project values both passed)
while scalar/boolean keys remain key-level overrides (project wins). Update tests accordingly.

Purpose: Users who set `--allow-tool` in their global config and add more tools in a project config
currently lose their global tools entirely. The fix preserves both sets.

Output: Modified `copilot-plus` (skip-map filtered to scalars only) + updated/new bats tests.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode.gsd/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<!-- Key interfaces the executor needs -->
<interfaces>
<!-- From copilot-plus lines 97-113 — the section being changed -->
```bash
# Collect project keys for key-level override (skip map for global processing)
declare -A project_keys=()
if [[ -f "$PROJECT_CONFIG" ]] && [[ -r "$PROJECT_CONFIG" ]]; then
  if ! jq empty "$PROJECT_CONFIG" 2>/dev/null; then
    echo "copilot-plus: error: invalid JSON in $PROJECT_CONFIG" >&2
    exit 1
  fi
  while IFS= read -r key; do
    project_keys["$key"]=1
  done < <(jq -r 'keys[] | select(startswith("--"))' "$PROJECT_CONFIG")
fi

# Build combined flags: global (minus overridden keys) + project
config_flags=()
declare -A no_skip=()
read_config_flags "$GLOBAL_CONFIG" config_flags project_keys
read_config_flags "$PROJECT_CONFIG" config_flags no_skip
```

<!-- The jq expression to get ONLY scalar/boolean keys (non-array) for the skip map: -->
<!--   keys[] | select(startswith("--")) | select((.value | type) != "array")          -->
<!-- But since we're iterating keys and need values too, use to_entries:                -->
<!--   to_entries[] | select(.key | startswith("--")) | select(.value | type != "array") | .key -->
</interfaces>

<!-- Existing tests being replaced/extended — lines 377-401 of tests/copilot.bats -->
<existing_tests>
# EXT-01g: uses --allow-tool (ARRAY) for override test — MUST change to scalar key
@test "EXT-01g: same key in both configs → project value used, global value suppressed" {
  write_config '{"--allow-tool":["A"]}'
  write_project_config '{"--allow-tool":["B"]}'
  ...

# EXT-01h: uses --allow-tool (ARRAY) for override test — MUST change to scalar key
@test "EXT-01h: project overrides --allow-tool but --model from global is still passed" {
  write_config '{"--allow-tool":["A"],"--model":"gpt-4.1"}'
  write_project_config '{"--allow-tool":["B"]}'
  ...
</existing_tests>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Fix project_keys skip-map to exclude array-typed keys</name>
  <files>copilot-plus</files>
  <behavior>
    - After fix: global `--allow-tool: ["A"]` + project `--allow-tool: ["B"]` → both `A` and `B` passed
    - After fix: global `--model: "gpt-4"` + project `--model: "gpt-4.1"` → only `gpt-4.1` passed
    - After fix: global `--add-dir: ["/foo"]` + project `--add-dir: ["/bar"]` → both `/foo` and `/bar` passed
    - After fix: global `--yolo: true` + project `--yolo: false` → `--yolo` NOT passed (project false wins)
  </behavior>
  <action>
Replace the `project_keys` population loop (lines 104-106) so it only inserts keys whose
value type in the project config is NOT "array". Use `jq -r` with `to_entries[]` to inspect
value types:

Current (adds ALL keys):
```bash
  while IFS= read -r key; do
    project_keys["$key"]=1
  done < <(jq -r 'keys[] | select(startswith("--"))' "$PROJECT_CONFIG")
```

Replace with (adds only non-array keys):
```bash
  while IFS= read -r key; do
    project_keys["$key"]=1
  done < <(jq -r 'to_entries[] | select(.key | startswith("--")) | select(.value | type != "array") | .key' "$PROJECT_CONFIG")
```

This means: scalar keys (string, number, boolean) from the project config enter the skip map
and suppress the global value. Array keys do NOT enter the skip map, so `read_config_flags`
processes both global and project values for array keys — both sets are appended.
  </action>
  <verify>
    <automated>bats tests/copilot.bats 2>&1 | tail -30</automated>
  </verify>
  <done>All existing bats tests pass (after Task 2 updates EXT-01g/h)</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Update EXT-01g/h and add EXT-01k/l for array additive behavior</name>
  <files>tests/copilot.bats</files>
  <behavior>
    - EXT-01g (updated): global `--model: "gpt-4"` + project `--model: "gpt-4.1"` → only `gpt-4.1` in args
    - EXT-01h (updated): global `--model: "gpt-4"` + project `--model: "gpt-4.1"` overrides; unrelated global key `--yolo: true` is still passed
    - EXT-01k (new): global `--allow-tool: ["A"]` + project `--allow-tool: ["B"]` → BOTH A and B in args
    - EXT-01l (new): global `--allow-tool: ["A"]` + project `--allow-tool: ["B"]` + global `--model: "gpt-4"` → A, B, and gpt-4 all present; no duplicates of A
  </behavior>
  <action>
**Update EXT-01g** — change from array key to scalar key override:
```bash
@test "EXT-01g: same scalar key in both configs → project value used, global value suppressed" {
  write_config '{"--model":"gpt-4"}'
  write_project_config '{"--model":"gpt-4.1"}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4" "$BATS_TMPDIR/stub_args"
}
```

**Update EXT-01h** — change from array key to scalar key override; keep second-key preservation:
```bash
@test "EXT-01h: project overrides --model but --yolo from global is still passed" {
  write_config '{"--model":"gpt-4","--yolo":true}'
  write_project_config '{"--model":"gpt-4.1"}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
}
```

**Add EXT-01k** after EXT-01j — array key is additive (global + project values both present):
```bash
# ============================================================
# EXT-01k: Same array key in both configs → values are additive (both included)
# ============================================================

@test "EXT-01k: same array key in both configs → both global and project values included" {
  write_config '{"--allow-tool":["GlobalTool"]}'
  write_project_config '{"--allow-tool":["ProjectTool"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx "GlobalTool" "$BATS_TMPDIR/stub_args"
  grep -qx "ProjectTool" "$BATS_TMPDIR/stub_args"
}
```

**Add EXT-01l** — array additive + scalar override in same config pair:
```bash
# ============================================================
# EXT-01l: Array key additive + scalar key override in same config pair
# ============================================================

@test "EXT-01l: array key additive while scalar key override in same invocation" {
  write_config '{"--allow-tool":["GlobalTool"],"--model":"gpt-4"}'
  write_project_config '{"--allow-tool":["ProjectTool"],"--model":"gpt-4.1"}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  # Array: both values present
  grep -qx "GlobalTool" "$BATS_TMPDIR/stub_args"
  grep -qx "ProjectTool" "$BATS_TMPDIR/stub_args"
  # Scalar: project wins
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4" "$BATS_TMPDIR/stub_args"
}
```

Insert EXT-01k and EXT-01l immediately after the EXT-01j test block (before ERG-03a section).
  </action>
  <verify>
    <automated>bats tests/copilot.bats 2>&1 | grep -E "^(ok|not ok|FAILED|[0-9]+ tests)"</automated>
  </verify>
  <done>
    All tests pass including: updated EXT-01g (scalar override), updated EXT-01h (scalar override + other key kept),
    EXT-01k (array additive), EXT-01l (array additive + scalar override mixed).
    Zero test failures.
  </done>
</task>

</tasks>

<verification>
```bash
bats tests/copilot.bats
```
All tests pass. Specifically confirm:
- EXT-01g: scalar `--model` override works
- EXT-01h: scalar `--model` override + unrelated global key preserved
- EXT-01k: array `--allow-tool` values from global AND project both appear
- EXT-01l: mixed scenario — array additive, scalar override
</verification>

<success_criteria>
- `bats tests/copilot.bats` exits 0 with all tests passing
- `copilot-plus`: `project_keys` skip map only contains non-array keys from project config
- `tests/copilot.bats`: EXT-01g/h use scalar keys; EXT-01k/l cover array additive behavior
- No regressions in any other EXT-* or ERG-* tests
</success_criteria>

<output>
After completion, create `.planning/quick/5-fix-array-key-merge-global-and-project-a/5-SUMMARY.md`
</output>
