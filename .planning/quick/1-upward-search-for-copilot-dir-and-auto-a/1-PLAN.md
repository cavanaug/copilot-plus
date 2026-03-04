---
phase: quick
plan: 1
type: tdd
wave: 1
depends_on: []
files_modified:
  - copilot-cli
  - tests/copilot.bats
autonomous: true
requirements: []
must_haves:
  truths:
    - "Running from a subdirectory finds the nearest parent's .copilot/config.json"
    - "The directory containing .copilot/ is auto-injected as --add-dir"
    - "Search stops at .git/ boundary (git root) — .copilot/ there is used if it exists"
    - "Search stops at filesystem root if neither .copilot/ nor .git/ found (silent passthrough)"
    - "Running from the .copilot/ directory itself (same level) still works (existing tests pass)"
    - "The auto-injected --add-dir appears after project config flags in argument order"
  artifacts:
    - path: "copilot-cli"
      provides: "find_project_config() bash function that walks upward"
      contains: "find_project_config"
    - path: "tests/copilot.bats"
      provides: "New EXT-02* tests for upward search and auto --add-dir"
      contains: "EXT-02"
  key_links:
    - from: "copilot-cli find_project_config()"
      to: "PROJECT_CONFIG variable"
      via: "replaces hardcoded ${PWD}/.copilot/config.json assignment"
    - from: "copilot-cli find_project_config()"
      to: "PROJECT_ROOT variable"
      via: "sets parent dir of found .copilot/ for --add-dir injection"
    - from: "PROJECT_ROOT"
      to: "exec copilot"
      via: "--add-dir $PROJECT_ROOT appended to config_flags after read_config_flags calls"
---

<objective>
Implement upward search for `.copilot/` directory starting from `$PWD`, and auto-inject the containing directory as `--add-dir`.

Purpose: Allow `copilot-cli` to work correctly from any subdirectory of a project — the nearest `.copilot/config.json` ancestor is found automatically, and copilot is given access to that project root via `--add-dir`.

Output: Updated `copilot-cli` with `find_project_config()` function; new `tests/copilot.bats` tests for upward search behavior.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@copilot-cli
@tests/copilot.bats
</context>

<tasks>

<!-- ============================================================
     TASK 1 — RED: Write failing tests for upward search
     ============================================================ -->
<task type="auto" tdd="true">
  <name>Task 1 (RED): Add failing bats tests for upward search + auto --add-dir</name>
  <files>tests/copilot.bats</files>
  <behavior>
    - EXT-02a: Running from a subdirectory (no .copilot/ there) finds .copilot/ in parent → project flags injected
    - EXT-02b: Running from a subdirectory → the parent that contains .copilot/ is auto-injected as --add-dir
    - EXT-02c: Running from the .copilot/ level itself still works (existing EXT-01* tests — do NOT break)
    - EXT-02d: Search stops at .git/ boundary — if .copilot/ exists at git root, it's used; if not, silent passthrough
    - EXT-02e: Auto --add-dir from upward search appears in stub_args
    - EXT-02f: Auto --add-dir from upward search is the PROJECT_ROOT (parent of .copilot/), not a subdir
  </behavior>
  <action>
Append new test helpers and test cases to `tests/copilot.bats`.

**New helper needed — `run_wrapper_in_subdir`:**
```bash
run_wrapper_in_subdir() {
  mkdir -p "$BATS_TMPDIR/project/sub"
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-cli\" \"\$@\"" -- "$@"
}
```

**Test EXT-02a** — `project/sub/` has no `.copilot/`; `project/.copilot/config.json` exists → project flags injected:
```bash
@test "EXT-02a: run from subdirectory finds parent .copilot/config.json → flags injected" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_subdir myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}
```

**Test EXT-02b** — parent dir containing `.copilot/` is auto-injected as `--add-dir`:
```bash
@test "EXT-02b: run from subdirectory → parent containing .copilot/ auto-injected as --add-dir" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_subdir myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}
```

**Test EXT-02c** — running from project root (`.copilot/` at same level) still auto-injects `--add-dir` as that root:
```bash
@test "EXT-02c: run from project root (.copilot/ at same level) → project root auto-injected as --add-dir" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}
```

**Test EXT-02d** — `.git/` present at project root, no `.copilot/` → silent passthrough (no project flags, no --add-dir from search):
```bash
@test "EXT-02d: .git/ at project root, no .copilot/ → silent passthrough, no auto --add-dir" {
  mkdir -p "$BATS_TMPDIR/project/.git"
  mkdir -p "$BATS_TMPDIR/project/sub"
  # No .copilot/ in project
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-cli\" myarg" 
  [ "$status" -eq 0 ]
  ! grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args" 2>/dev/null || true
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}
```

**Test EXT-02e** — `.git/` present alongside `.copilot/` → `.copilot/config.json` used AND `--add-dir` injected:
```bash
@test "EXT-02e: .git/ and .copilot/ both at project root → config used, --add-dir injected" {
  mkdir -p "$BATS_TMPDIR/project/.git"
  write_project_config '{"--allow-tool":["bash"]}'
  mkdir -p "$BATS_TMPDIR/project/sub"
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-cli\" myarg"
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}
```

Run tests — they should FAIL (red). The EXT-02a/b/c tests will fail because the current script only checks `$PWD/.copilot/`.
  </action>
  <verify>
    <automated>bats tests/copilot.bats 2>&1 | grep -E "EXT-02|not ok" | head -20</automated>
  </verify>
  <done>New EXT-02* tests exist in tests/copilot.bats and fail (red). All pre-existing tests still pass when run directly from a `$PWD` that has `.copilot/` (EXT-01* unaffected by this task).</done>
</task>

<!-- ============================================================
     TASK 2 — GREEN: Implement upward search in copilot-cli
     ============================================================ -->
<task type="auto" tdd="true">
  <name>Task 2 (GREEN): Implement find_project_config() upward search + auto --add-dir in copilot-cli</name>
  <files>copilot-cli</files>
  <behavior>
    - find_project_config() walks upward from $PWD until .copilot/ found or .git/ found or / reached
    - Sets PROJECT_CONFIG to the found .copilot/config.json path (or empty if none found)
    - Sets PROJECT_ROOT to the directory containing the found .copilot/ (or empty if none found)
    - If PROJECT_ROOT is non-empty, appends "--add-dir" "$PROJECT_ROOT" to config_flags after project config flags
    - The existing PROJECT_CONFIG="${PWD}/.copilot/config.json" line is removed/replaced
    - COPILOT_ARGS includes the --add-dir flag (it's part of config_flags)
  </behavior>
  <action>
Replace the hardcoded `PROJECT_CONFIG` line with a `find_project_config()` function and call it.

**Replace lines 4-5 (`GLOBAL_CONFIG` + `PROJECT_CONFIG` assignments) with:**

```bash
GLOBAL_CONFIG="${HOME}/.copilot/config.json"

# Walk upward from $PWD to find the nearest .copilot/ directory.
# Stops at the first .copilot/ found, or at a .git/ boundary (project root), or at /.
# Sets PROJECT_CONFIG and PROJECT_ROOT.
find_project_config() {
  local dir="$PWD"
  while true; do
    if [[ -d "$dir/.copilot" ]]; then
      PROJECT_CONFIG="$dir/.copilot/config.json"
      PROJECT_ROOT="$dir"
      return
    fi
    if [[ -d "$dir/.git" ]]; then
      # Reached git root without finding .copilot/ — no project config
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    local parent
    parent="$(dirname "$dir")"
    if [[ "$parent" == "$dir" ]]; then
      # Reached filesystem root
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    dir="$parent"
  done
}

PROJECT_CONFIG=""
PROJECT_ROOT=""
find_project_config
```

**After `read_config_flags "$PROJECT_CONFIG" config_flags no_skip` (line 74), add auto --add-dir injection:**

```bash
# Auto-inject project root as --add-dir if a .copilot/ was found via upward search
if [[ -n "$PROJECT_ROOT" ]]; then
  config_flags+=("--add-dir" "$PROJECT_ROOT")
fi
```

**Full updated script structure (copilot-cli):**

```bash
#!/usr/bin/env bash
set -euo pipefail

GLOBAL_CONFIG="${HOME}/.copilot/config.json"

# Walk upward from $PWD to find the nearest .copilot/ directory.
# Stops at the first .copilot/ found, or at a .git/ boundary (project root), or at /.
# Sets PROJECT_CONFIG and PROJECT_ROOT.
find_project_config() {
  local dir="$PWD"
  while true; do
    if [[ -d "$dir/.copilot" ]]; then
      PROJECT_CONFIG="$dir/.copilot/config.json"
      PROJECT_ROOT="$dir"
      return
    fi
    if [[ -d "$dir/.git" ]]; then
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    local parent
    parent="$(dirname "$dir")"
    if [[ "$parent" == "$dir" ]]; then
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    dir="$parent"
  done
}

PROJECT_CONFIG=""
PROJECT_ROOT=""
find_project_config

# Read all -- flags from a config file into a named array (by reference)
# Usage: read_config_flags <config_file> <array_ref> <skip_keys_assoc_array_ref>
# skip_keys_assoc_array_ref: associative array of keys to skip (for key-level override)
read_config_flags() {
  local config_file="$1"
  local -n _flags_ref="$2"
  local -n _skip_ref="$3"

  [[ -f "$config_file" ]] && [[ -r "$config_file" ]] || return 0

  if ! jq empty "$config_file" 2>/dev/null; then
    echo "copilot-wrapper: error: invalid JSON in $config_file" >&2
    exit 1
  fi

  while IFS= read -r key; do
    if [[ -v _skip_ref["$key"] ]]; then
      continue
    fi

    local vtype
    vtype=$(jq -r --arg k "$key" '.[$k] | type' "$config_file")

    case "$vtype" in
      array)
        while IFS= read -r element; do
          _flags_ref+=("$key" "$element")
        done < <(jq -r --arg k "$key" '.[$k][]' "$config_file")
        ;;
      boolean)
        local val
        val=$(jq -r --arg k "$key" '.[$k]' "$config_file")
        if [[ "$val" == "true" ]]; then
          _flags_ref+=("$key")
        fi
        ;;
      string|number)
        local val
        val=$(jq -r --arg k "$key" '.[$k]' "$config_file")
        _flags_ref+=("$key" "$val")
        ;;
      object|null|*)
        echo "copilot-wrapper: error: unsupported value type '$vtype' for key '$key' in $config_file" >&2
        exit 1
        ;;
    esac
  done < <(jq -r 'keys[] | select(startswith("--"))' "$config_file")
}

# Collect project keys for key-level override (skip map for global processing)
declare -A project_keys=()
if [[ -n "$PROJECT_CONFIG" ]] && [[ -f "$PROJECT_CONFIG" ]] && [[ -r "$PROJECT_CONFIG" ]]; then
  if ! jq empty "$PROJECT_CONFIG" 2>/dev/null; then
    echo "copilot-wrapper: error: invalid JSON in $PROJECT_CONFIG" >&2
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

# Auto-inject project root as --add-dir if a .copilot/ was found via upward search
if [[ -n "$PROJECT_ROOT" ]]; then
  config_flags+=("--add-dir" "$PROJECT_ROOT")
fi

# Export COPILOT_ARGS: shell-quoted, space-separated config-injected flags only (not user args)
if [[ ${#config_flags[@]} -eq 0 ]]; then
  COPILOT_ARGS=""
else
  COPILOT_ARGS=$(printf '%q ' "${config_flags[@]}")
  COPILOT_ARGS="${COPILOT_ARGS% }"
fi
export COPILOT_ARGS

exec copilot "${config_flags[@]+"${config_flags[@]}"}" "$@"
```

**Note on existing test EXT-01b** — that test calls `run_wrapper_in_project` (which runs from `$BATS_TMPDIR/project`) with no project `.copilot/`. The upward search will walk up from `$BATS_TMPDIR/project` → finds no `.copilot/` there → walks up to `$BATS_TMPDIR` → finds `.copilot/` there (the global config dir created in `setup()`). This would BREAK EXT-01b unless handled.

**Fix:** The upward search must NOT cross into `$HOME` — the global config `~/.copilot/` is separate and should not be discovered by the project search. Add a `.git/` stop or a `$HOME` boundary check:

```bash
find_project_config() {
  local dir="$PWD"
  while true; do
    if [[ -d "$dir/.copilot" ]]; then
      PROJECT_CONFIG="$dir/.copilot/config.json"
      PROJECT_ROOT="$dir"
      return
    fi
    if [[ -d "$dir/.git" ]]; then
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    local parent
    parent="$(dirname "$dir")"
    # Stop at HOME boundary — don't pick up global ~/.copilot as project config
    if [[ "$parent" == "$HOME" ]] || [[ "$dir" == "$HOME" ]]; then
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    if [[ "$parent" == "$dir" ]]; then
      PROJECT_CONFIG=""
      PROJECT_ROOT=""
      return
    fi
    dir="$parent"
  done
}
```

Wait — but in tests, `HOME=$BATS_TMPDIR` and project is `$BATS_TMPDIR/project`. So the walk goes: `project` (no `.copilot/`, no `.git/`) → parent is `$BATS_TMPDIR` which equals `$HOME` → stop. This correctly prevents the global `$BATS_TMPDIR/.copilot/` from being picked up as a project config. Use this boundary-aware version.

After implementing, run the full test suite.
  </action>
  <verify>
    <automated>bats tests/copilot.bats</automated>
  </verify>
  <done>All tests pass (green), including all pre-existing CONF-*, MAP-*, INVK-*, DIST-*, EXT-01*, ERG-03* tests AND the new EXT-02* tests. The `--add-dir` is auto-injected when `.copilot/` is found during upward search.</done>
</task>

</tasks>

<verification>
Full test run:

```bash
bats tests/copilot.bats
```

All tests pass. Specifically verify:
- EXT-01b still passes (no unintended project config pickup when no .copilot/ in project dir)
- EXT-02b passes (--add-dir $BATS_TMPDIR/project appears in stub_args when run from subdir)
- EXT-02c passes (--add-dir also injected when run from the project root itself)
- EXT-02d passes (no --add-dir when .git/ reached before .copilot/)
</verification>

<success_criteria>
- `bats tests/copilot.bats` exits 0 with all tests passing
- `find_project_config()` function exists in `copilot-cli`
- Walking upward from a subdirectory correctly finds parent `.copilot/config.json`
- Search stops at `$HOME` boundary (prevents global config pickup)  
- Search stops at `.git/` boundary (project root, no `.copilot/` beyond)
- Found project root is injected as `--add-dir` in `config_flags`
- `COPILOT_ARGS` includes the `--add-dir` flag
</success_criteria>

<output>
No SUMMARY.md required for quick plans. Changes are complete when all tests pass.
</output>
