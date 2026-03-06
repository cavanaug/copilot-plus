---
phase: quick-9
plan: 9
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus
  - tests/copilot.bats
autonomous: true
requirements: [QUICK-9]

must_haves:
  truths:
    - "A non-existent --add-dir value from config is silently omitted (no flag passed to copilot)"
    - "An existing --add-dir value from config is still passed through as normal"
    - "Auto-injected PROJECT_ROOT --add-dir is omitted if that directory no longer exists"
  artifacts:
    - path: "copilot-plus"
      provides: "Existence-check guard around --add-dir path injection"
      contains: "-d"
    - path: "tests/copilot.bats"
      provides: "Tests covering non-existent --add-dir omission"
  key_links:
    - from: "read_config_flags (array branch)"
      to: "config_flags array"
      via: "directory existence check before _flags_ref+="
      pattern: '-d.*_flags_ref'
    - from: "auto-inject PROJECT_ROOT block"
      to: "config_flags array"
      via: "directory existence check"
      pattern: '-d.*PROJECT_ROOT'
---

<objective>
Guard all `--add-dir` path injections (from config and auto-inject) against non-existent directories.

Purpose: Passing a non-existent directory to `copilot --add-dir` likely causes an error or unexpected behavior. When a configured or auto-detected path doesn't exist on disk, silently omit it rather than forwarding a bad path.

Output: Updated `copilot-plus` script + new bats tests covering the omission behavior.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@copilot-plus
@tests/copilot.bats
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add directory-existence guards for --add-dir in copilot-plus</name>
  <files>copilot-plus, tests/copilot.bats</files>
  <behavior>
    - Test MAP-ADD-DIR-01: `--add-dir ["/nonexistent/path"]` in config → `--add-dir` flag NOT passed to stub
    - Test MAP-ADD-DIR-02: `--add-dir ["/tmp"]` in config (exists) → `--add-dir /tmp` still passed to stub
    - Test MAP-ADD-DIR-03: auto-inject PROJECT_ROOT that no longer exists → `--add-dir` NOT passed to stub (simulate by writing project config but rm -rf'ing the project dir before run — not feasible; instead test that a `--add-dir` value pointing to a nonexistent dir is omitted)
    - Test MAP-ADD-DIR-04: mix of existing + non-existing paths in `--add-dir` array → only existing paths are passed
  </behavior>
  <action>
**Write tests FIRST (RED), then implement (GREEN).**

### Tests to add in tests/copilot.bats (after the EXT-02e block, before DRY-RUN-01):

Add a new section `# EXT-02f..EXT-02i: --add-dir non-existent directory omission`:

**EXT-02f**: `--add-dir` value is a nonexistent directory → omitted from args
```
write_project_config '{"--add-dir":["/nonexistent/path/that/does/not/exist"]}'
run_wrapper_in_project myarg
[ "$status" -eq 0 ]
! grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args" 2>/dev/null || true
! grep -qx "/nonexistent/path/that/does/not/exist" "$BATS_TMPDIR/stub_args" 2>/dev/null || true
```

**EXT-02g**: `--add-dir` value is an existing directory (/tmp) → still passed
```
write_project_config '{"--add-dir":["/tmp"]}'
run_wrapper_in_project myarg
[ "$status" -eq 0 ]
grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
grep -qx "/tmp" "$BATS_TMPDIR/stub_args"
```

**EXT-02h**: `--add-dir` array with one existing + one nonexistent → only existing one passed
```
write_project_config "{\"--add-dir\":[\"/tmp\",\"/nonexistent/path/that/does/not/exist\"]}"
run_wrapper_in_project myarg
[ "$status" -eq 0 ]
grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
grep -qx "/tmp" "$BATS_TMPDIR/stub_args"
! grep -qx "/nonexistent/path/that/does/not/exist" "$BATS_TMPDIR/stub_args" 2>/dev/null || true
# Only one --add-dir flag (not two)
count=$(grep -cx -- "--add-dir" "$BATS_TMPDIR/stub_args" || echo 0)
[ "$count" -eq 1 ]
```

### Implementation changes in copilot-plus:

**1. In `read_config_flags`, in the `array` branch** — after `envsubst`, check if key is `--add-dir` and the expanded path doesn't exist as a directory, then skip:

Change the array branch from:
```bash
while IFS= read -r element; do
    _flags_ref+=("$key" "$(envsubst <<<"$element")")
done < <(jq -r --arg k "$key" '.[$k][]' "$config_file")
```
To:
```bash
while IFS= read -r element; do
    local expanded
    expanded="$(envsubst <<<"$element")"
    if [[ "$key" == "--add-dir" ]] && [[ ! -d "$expanded" ]]; then
        continue
    fi
    _flags_ref+=("$key" "$expanded")
done < <(jq -r --arg k "$key" '.[$k][]' "$config_file")
```

**2. In `read_config_flags`, in the `string | number` branch** — same guard for scalar `--add-dir`:

Change:
```bash
val=$(jq -r --arg k "$key" '.[$k]' "$config_file")
_flags_ref+=("$key" "$(envsubst <<<"$val")")
```
To:
```bash
val=$(jq -r --arg k "$key" '.[$k]' "$config_file")
local expanded
expanded="$(envsubst <<<"$val")"
if [[ "$key" == "--add-dir" ]] && [[ ! -d "$expanded" ]]; then
    : # skip non-existent directory
else
    _flags_ref+=("$key" "$expanded")
fi
```

**3. Auto-inject PROJECT_ROOT block (lines ~134-137)** — add existence guard:

Change:
```bash
# Auto-inject project root as --add-dir if a .copilot/ was found via upward search
if [[ -n "$PROJECT_ROOT" ]]; then
    config_flags+=("--add-dir" "$PROJECT_ROOT")
fi
```
To:
```bash
# Auto-inject project root as --add-dir if a .copilot/ was found via upward search (only if dir exists)
if [[ -n "$PROJECT_ROOT" ]] && [[ -d "$PROJECT_ROOT" ]]; then
    config_flags+=("--add-dir" "$PROJECT_ROOT")
fi
```

Note: The PROJECT_ROOT guard change is technically redundant (find_project_config only sets it when `$dir/.copilot` exists, so the dir must exist at that moment), but it's defensive and documents intent. The main impact is the `read_config_flags` changes for config-defined `--add-dir` arrays.
  </action>
  <verify>
    <automated>cd /home/cavanaug/wip_other/projects/copilot-plus && bats tests/copilot.bats 2>&1 | tail -20</automated>
  </verify>
  <done>
    - All existing bats tests still pass
    - New EXT-02f, EXT-02g, EXT-02h tests pass
    - `--add-dir /nonexistent/path` is omitted from the copilot invocation
    - `--add-dir /tmp` (existing) still passed through
    - Mixed array (one good, one bad) only passes the good one
  </done>
</task>

</tasks>

<verification>
Run full test suite: `bats tests/copilot.bats`

All tests pass, including new EXT-02f/g/h coverage.
</verification>

<success_criteria>
- Non-existent `--add-dir` paths silently omitted (no error, no flag passed to copilot)
- Existing `--add-dir` paths pass through unchanged
- Behavior applies to both config-sourced and auto-injected paths
- Zero regressions in existing test suite
</success_criteria>

<output>
After completion, create `.planning/quick/9-when-building-the-cli-if-the-directory-b/9-SUMMARY.md`

Update `.planning/STATE.md`:
- `last_activity`: `2026-03-06 - Completed quick task 9: omit non-existent --add-dir paths from CLI`
- Add row to Quick Tasks Completed table:
  `| 9 | omit non-existent --add-dir paths from CLI | 2026-03-06 | {commit} | [9-when-building-the-cli-if-the-directory-b](.planning/quick/9-when-building-the-cli-if-the-directory-b/) |`
</output>
