#!/usr/bin/env bats
# Test suite for the copilot wrapper script
# Covers all 16 requirements: CONF-01..03, MAP-01..07, INVK-01..04, DIST-01..02
# Phase 2 additions: EXT-01 (per-project config), ERG-03 (COPILOT_ARGS export)

setup() {
  # Create stub copilot binary (also dumps env for COPILOT_ARGS testing)
  mkdir -p "$BATS_TMPDIR/bin"
  STUB_ARGS_FILE="$BATS_TMPDIR/stub_args"
  printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' "$@" > "%s"\nenv > "%s"\nexit 0\n' \
    "$STUB_ARGS_FILE" "$BATS_TMPDIR/stub_env" > "$BATS_TMPDIR/bin/copilot"
  chmod +x "$BATS_TMPDIR/bin/copilot"

  # Create .copilot config directory
  mkdir -p "$BATS_TMPDIR/.copilot"
}

teardown() {
  rm -f "$BATS_TMPDIR/stub_args"
  rm -f "$BATS_TMPDIR/.copilot/config.json"
  rm -rf "$BATS_TMPDIR/project"
  rm -f "$BATS_TMPDIR/stub_env"
}

# Helper: run wrapper with stub copilot
run_wrapper() {
  run env HOME="$BATS_TMPDIR" PATH="$BATS_TMPDIR/bin:$PATH" bash "$BATS_TEST_DIRNAME/../copilot-plus" "$@"
}

# Helper: run wrapper with stub copilot in project directory (for per-project config tests)
run_wrapper_in_project() {
  mkdir -p "$BATS_TMPDIR/project"
  run bash -c "cd \"$BATS_TMPDIR/project\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-plus\" \"\$@\"" -- "$@"
}

# Helper: write global config JSON
write_config() {
  printf '%s\n' "$1" > "$BATS_TMPDIR/.copilot/config.json"
}

# Helper: write project config JSON
write_project_config() {
  mkdir -p "$BATS_TMPDIR/project/.copilot"
  printf '%s\n' "$1" > "$BATS_TMPDIR/project/.copilot/config.json"
}

# ============================================================
# CONF-01: Wrapper reads ~/.copilot/config.json at invocation
# ============================================================

@test "CONF-01: valid config is read and flags are injected" {
  write_config '{"--yolo":true}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# CONF-02: Missing or unreadable config → silent passthrough
# ============================================================

@test "CONF-02: missing config file → exit 0, stub called with only user args, no error" {
  # No config file created in setup
  run_wrapper myarg
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

@test "CONF-02: unreadable config file → exit 0, stub called with only user args" {
  write_config '{"--yolo":true}'
  chmod 000 "$BATS_TMPDIR/.copilot/config.json"
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
  chmod 644 "$BATS_TMPDIR/.copilot/config.json"
}

# ============================================================
# CONF-03: Invalid JSON → exit non-zero, error on stderr, stub NOT called
# ============================================================

@test "CONF-03: invalid JSON → exit non-zero, error on stderr, stub not called" {
  write_config 'not valid json {'
  run_wrapper myarg
  [ "$status" -ne 0 ]
  [[ "$output" == *"error"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# MAP-01 + MAP-02: Array value → one --key value pair per element
# ============================================================

@test "MAP-01+MAP-02: array value → one --key value pair per element" {
  write_config '{"--allow-tool":["bash","shell"]}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx "shell" "$BATS_TMPDIR/stub_args"
  # Verify both pairs present with correct order: --allow-tool bash --allow-tool shell myarg
  args=$(cat "$BATS_TMPDIR/stub_args")
  echo "$args" | grep -qx -- "--allow-tool"
  echo "$args" | grep -qx "bash"
  echo "$args" | grep -qx "shell"
}

# ============================================================
# MAP-01 + MAP-03: Boolean true → bare flag
# ============================================================

@test "MAP-01+MAP-03: boolean true → bare --key flag injected" {
  write_config '{"--yolo":true}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# MAP-01 + MAP-04: Boolean false → key skipped entirely
# ============================================================

@test "MAP-01+MAP-04: boolean false → key skipped, stub still called" {
  write_config '{"--yolo":false}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  ! grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# MAP-01 + MAP-05: String value → single --key value pair
# ============================================================

@test "MAP-01+MAP-05: string value → single --key value pair" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# MAP-01 + MAP-05: Number value → single --key value pair
# ============================================================

@test "MAP-01+MAP-05: number value → single --key value pair" {
  write_config '{"--max-autopilot-continues":5}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--max-autopilot-continues" "$BATS_TMPDIR/stub_args"
  grep -qx "5" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# MAP-06: Object value → exit non-zero, error on stderr, stub NOT called
# ============================================================

@test "MAP-06: object value → exit non-zero, error on stderr, stub not called" {
  write_config '{"--bad":{}}'
  run_wrapper myarg
  [ "$status" -ne 0 ]
  [[ "$output" == *"error"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# MAP-06: Null value → exit non-zero, error on stderr, stub NOT called
# ============================================================

@test "MAP-06: null value → exit non-zero, error on stderr, stub not called" {
  write_config '{"--bad":null}'
  run_wrapper myarg
  [ "$status" -ne 0 ]
  [[ "$output" == *"error"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# MAP-07: Keys without -- prefix → silently ignored
# ============================================================

@test "MAP-07: keys without -- prefix → silently ignored, stub called normally" {
  write_config '{"model":"gpt-4.1","theme":"dark"}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  ! grep -qx "model" "$BATS_TMPDIR/stub_args"
  ! grep -qx "theme" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# INVK-01: Config flags prepended, user args appended after
# ============================================================

@test "INVK-01: config-injected flags prepended, user args appended after" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper userarg1 userarg2
  [ "$status" -eq 0 ]
  args=$(cat "$BATS_TMPDIR/stub_args")
  # --model gpt-4.1 must appear before userarg1 and userarg2
  model_line=$(echo "$args" | grep -n -- "--model" | head -1 | cut -d: -f1)
  val_line=$(echo "$args" | grep -n "gpt-4.1" | head -1 | cut -d: -f1)
  user1_line=$(echo "$args" | grep -n "userarg1" | head -1 | cut -d: -f1)
  [ -n "$model_line" ]
  [ -n "$val_line" ]
  [ -n "$user1_line" ]
  [ "$val_line" -lt "$user1_line" ]
}

# ============================================================
# INVK-02: Config flags + user flags of same type both present (additive)
# ============================================================

@test "INVK-02: config flags and user-supplied flags of same type both present (additive)" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper --model gpt-4o myarg
  [ "$status" -eq 0 ]
  # Both --model occurrences should be present
  model_count=$(grep -cx -- "--model" "$BATS_TMPDIR/stub_args")
  [ "$model_count" -eq 2 ]
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4o" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# INVK-03 + INVK-04: exec semantics — wrapper process replaced (stub receives args)
# ============================================================

@test "INVK-03+INVK-04: exec semantics — stub receives correct args (wrapper replaced)" {
  write_config '{"--yolo":true}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  # If exec works correctly, stub_args exists and contains expected args
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# Multiple -- keys: all injected correctly
# ============================================================

@test "Multiple -- keys in config → all injected respecting their type" {
  write_config '{"--yolo":true,"--model":"gpt-4.1","--allow-tool":["bash","write"]}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx "write" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# Empty array value → no flags injected for that key, no error
# ============================================================

@test "Empty array value → no flags injected, stub called normally, no error" {
  write_config '{"--allow-tool":[]}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  ! grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# DIST-02: Script is named 'copilot-plus', invoked via alias copilot=copilot-plus
# ============================================================

@test "DIST-02: wrapper named copilot-plus is invoked via shell alias" {
  write_config '{}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  # Stub was called (not the real copilot) meaning PATH ordering worked
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01a: Project config only (no global config) → flags injected from project config
# ============================================================

@test "EXT-01a: project config only → flags injected from project config" {
  # No global config created; only project config
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01b: Project config missing → silent, no project flags (global still applied)
# ============================================================

@test "EXT-01b: project config missing → silent, global flags still applied" {
  write_config '{"--model":"gpt-4.1"}'
  # No project config created
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01c: Project config invalid JSON → exit non-zero, error on stderr, stub not called
# ============================================================

@test "EXT-01c: project config invalid JSON → exit non-zero, error on stderr, stub not called" {
  write_project_config 'not valid json {'
  run_wrapper_in_project myarg
  [ "$status" -ne 0 ]
  [[ "$output" == *"error"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# EXT-01d: Project config object value → exit non-zero, error on stderr, stub not called
# ============================================================

@test "EXT-01d: project config object value → exit non-zero, error on stderr, stub not called" {
  write_project_config '{"--bad":{}}'
  run_wrapper_in_project myarg
  [ "$status" -ne 0 ]
  [[ "$output" == *"error"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# EXT-01e: Both configs present, different keys → both flags appear in output (additive)
# ============================================================

@test "EXT-01e: global --model + project --add-dir → both flags present (additive merge)" {
  write_config '{"--model":"gpt-4.1"}'
  write_project_config '{"--add-dir":["/tmp"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "/tmp" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01f: Both configs present → global flags come before project flags in arg order
# ============================================================

@test "EXT-01f: global flags appear before project flags in final argument list" {
  write_config '{"--model":"gpt-4.1"}'
  write_project_config '{"--add-dir":["/tmp"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  args=$(cat "$BATS_TMPDIR/stub_args")
  model_line=$(echo "$args" | grep -n -- "--model" | head -1 | cut -d: -f1)
  adddir_line=$(echo "$args" | grep -n -- "--add-dir" | head -1 | cut -d: -f1)
  [ -n "$model_line" ]
  [ -n "$adddir_line" ]
  # Global (--model) must appear before project (--add-dir)
  [ "$model_line" -lt "$adddir_line" ]
}

# ============================================================
# EXT-01g: Same key in both configs → only project value used (key-level override)
# ============================================================

@test "EXT-01g: same scalar key in both configs → project value used, global value suppressed" {
  write_config '{"--model":"gpt-4"}'
  write_project_config '{"--model":"gpt-4.1"}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01h: Same key overridden + another key kept → project wins for overridden, global kept for other
# ============================================================

@test "EXT-01h: project overrides --model but --yolo from global is still passed" {
  write_config '{"--model":"gpt-4","--yolo":true}'
  write_project_config '{"--model":"gpt-4.1"}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  ! grep -qx "gpt-4" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01i: Project config empty JSON {} → no project flags, global still applied
# ============================================================

@test "EXT-01i: project config empty JSON → no project flags, global still applied" {
  write_config '{"--model":"gpt-4.1"}'
  write_project_config '{}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-01j: Project has boolean true key not in global → injected additively
# ============================================================

@test "EXT-01j: project boolean true key not in global → injected additively" {
  write_config '{"--model":"gpt-4.1"}'
  write_project_config '{"--yolo":true}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--model" "$BATS_TMPDIR/stub_args"
  grep -qx "gpt-4.1" "$BATS_TMPDIR/stub_args"
}

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

# ============================================================
# EXT-01m: Type conflict (scalar --add-dir in global, array in project) → error, exit non-zero
# ============================================================

@test "EXT-01m: type conflict for --add-dir (scalar global, array project) → error on stderr, exit non-zero, stub not called" {
  write_config '{"--add-dir":"/global/folder"}'
  write_project_config '{"--add-dir":["/project/folder1","/project/folder2"]}'
  run_wrapper_in_project myarg
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "type conflict"
  [ ! -f "$BATS_TMPDIR/stub_args" ] || ! grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# ERG-03a: Config with flags → COPILOT_ARGS exported with shell-quoted flags
# ============================================================

@test "ERG-03a: config with flags → COPILOT_ARGS exported and contains config flags" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  # Check COPILOT_ARGS was set in the stub's environment
  grep -q "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env"
  copilot_args=$(grep "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env" | cut -d= -f2-)
  [[ "$copilot_args" == *"--model"* ]]
  [[ "$copilot_args" == *"gpt-4.1"* ]]
}

# ============================================================
# ERG-03b: No config (or empty config) → COPILOT_ARGS exported as empty string
# ============================================================

@test "ERG-03b: no config flags → COPILOT_ARGS exported as empty string" {
  write_config '{}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -q "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env"
  copilot_args=$(grep "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env" | cut -d= -f2-)
  [ -z "$copilot_args" ]
}

# ============================================================
# ERG-03c: COPILOT_ARGS contains only config-injected flags, NOT user-supplied args
# ============================================================

@test "ERG-03c: COPILOT_ARGS contains only config flags, NOT user-supplied args" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper myuserarg
  [ "$status" -eq 0 ]
  copilot_args=$(grep "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env" | cut -d= -f2-)
  [[ "$copilot_args" == *"--model"* ]]
  # User arg must NOT appear in COPILOT_ARGS
  [[ "$copilot_args" != *"myuserarg"* ]]
}

# ============================================================
# ERG-03d: Special shell chars in value properly quoted in COPILOT_ARGS
# ============================================================

@test "ERG-03d: special shell chars (e.g. shell(git:*)) properly quoted in COPILOT_ARGS" {
  write_config '{"--allow-tool":["shell(git:*)"]}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  grep -q "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env"
  copilot_args=$(grep "^COPILOT_ARGS=" "$BATS_TMPDIR/stub_env" | cut -d= -f2-)
  # COPILOT_ARGS should contain --allow-tool and the value (possibly quoted)
  [[ "$copilot_args" == *"--allow-tool"* ]]
  # The value should be present in some form (shell-quoted)
  [[ "$copilot_args" == *"shell"* ]]
  [[ "$copilot_args" == *"git"* ]]
}

# Helper: run wrapper from a subdirectory of the project (no .copilot/ in subdir)
run_wrapper_in_subdir() {
  mkdir -p "$BATS_TMPDIR/project/sub"
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-plus\" \"\$@\"" -- "$@"
}

# ============================================================
# EXT-02a: Running from subdirectory finds parent .copilot/config.json → flags injected
# ============================================================

@test "EXT-02a: run from subdirectory finds parent .copilot/config.json → flags injected" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_subdir myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-02b: Parent containing .copilot/ auto-injected as --add-dir
# ============================================================

@test "EXT-02b: run from subdirectory → parent containing .copilot/ auto-injected as --add-dir" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_subdir myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-02c: Run from project root (.copilot/ at same level) → project root auto-injected as --add-dir
# ============================================================

@test "EXT-02c: run from project root (.copilot/ at same level) → project root auto-injected as --add-dir" {
  write_project_config '{"--allow-tool":["bash"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-02d: .git/ at project root, no .copilot/ → silent passthrough, no auto --add-dir
# ============================================================

@test "EXT-02d: .git/ at project root, no .copilot/ → silent passthrough, no auto --add-dir" {
  mkdir -p "$BATS_TMPDIR/project/.git"
  mkdir -p "$BATS_TMPDIR/project/sub"
  # No .copilot/ in project
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-plus\" myarg"
  [ "$status" -eq 0 ]
  ! grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args" 2>/dev/null || true
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-02e: .git/ and .copilot/ both at project root → config used, --add-dir injected
# ============================================================

@test "EXT-02e: .git/ and .copilot/ both at project root → config used, --add-dir injected" {
  mkdir -p "$BATS_TMPDIR/project/.git"
  write_project_config '{"--allow-tool":["bash"]}'
  mkdir -p "$BATS_TMPDIR/project/sub"
  run bash -c "cd \"$BATS_TMPDIR/project/sub\" && env HOME=\"$BATS_TMPDIR\" PATH=\"$BATS_TMPDIR/bin:$PATH\" bash \"$BATS_TEST_DIRNAME/../copilot-plus\" myarg"
  [ "$status" -eq 0 ]
  grep -qx -- "--allow-tool" "$BATS_TMPDIR/stub_args"
  grep -qx "bash" "$BATS_TMPDIR/stub_args"
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "$BATS_TMPDIR/project" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# EXT-02f..EXT-02h: --add-dir non-existent directory omission
# ============================================================

@test "EXT-02f: --add-dir value is a nonexistent directory → omitted from args" {
  write_project_config '{"--add-dir":["/nonexistent/path/that/does/not/exist"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  ! grep -qx "/nonexistent/path/that/does/not/exist" "$BATS_TMPDIR/stub_args"
}

@test "EXT-02g: --add-dir value is an existing directory (/tmp) → still passed" {
  write_project_config '{"--add-dir":["/tmp"]}'
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "/tmp" "$BATS_TMPDIR/stub_args"
}

@test "EXT-02h: --add-dir array with one existing + one nonexistent → only existing one passed" {
  write_project_config "{\"--add-dir\":[\"/tmp\",\"/nonexistent/path/that/does/not/exist\"]}"
  run_wrapper_in_project myarg
  [ "$status" -eq 0 ]
  grep -qx -- "--add-dir" "$BATS_TMPDIR/stub_args"
  grep -qx "/tmp" "$BATS_TMPDIR/stub_args"
  ! grep -qx "/nonexistent/path/that/does/not/exist" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# DRY-RUN-01: +cmd → prints command to stdout, does NOT exec copilot
# ============================================================

@test "DRY-RUN-01: +cmd with no config → prints 'copilot' + user args, stub not called" {
  run_wrapper +cmd myarg
  [ "$status" -eq 0 ]
  [[ "$output" == 'copilot "myarg"' ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-02: +cmd with config flags → flags appear in printed command
# ============================================================

@test "DRY-RUN-02: +cmd with config → prints full command with config flags + user args" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +cmd myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"copilot"* ]]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [[ "$output" == *"myarg"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-03: +cmd with no args and no config → prints just 'copilot'
# ============================================================

@test "DRY-RUN-03: +cmd only, no config, no user args → prints 'copilot'" {
  run_wrapper +cmd
  [ "$status" -eq 0 ]
  [[ "$output" == "copilot" ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-04: +cmd does not appear in printed command output
# ============================================================

@test "DRY-RUN-04: +cmd itself does not appear in the printed command" {
  run_wrapper +cmd myarg
  [ "$status" -eq 0 ]
  [[ "$output" != *"+cmd"* ]]
}

# ============================================================
# DRY-RUN-05: Without +cmd, existing exec behavior unchanged
# ============================================================

@test "DRY-RUN-05: without +cmd → normal exec, stub called as before" {
  write_config '{"--yolo":true}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx -- "--yolo" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# DRY-RUN-06: +cmd with special-char value → value is shell-quoted
# ============================================================

@test "DRY-RUN-06: +cmd with special-char config value → value is double-quoted in output" {
  write_config '{"--thread":"shell(git:*)"}'
  run_wrapper +cmd
  [ "$status" -eq 0 ]
  [[ "$output" == *'"shell(git:*)"'* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-07: +cmd output — --flags are unquoted, values are double-quoted
# ============================================================

@test "DRY-RUN-07: +cmd output has bare --flags and double-quoted values" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +cmd myarg
  [ "$status" -eq 0 ]
  # --model appears bare (no quotes around it)
  [[ "$output" == *" --model "* ]]
  # value is double-quoted
  [[ "$output" == *'"gpt-4.1"'* ]]
  # user arg is double-quoted
  [[ "$output" == *'"myarg"'* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# DRY-RUN-08: +cmd with env var in config value → variable expanded in output
# ============================================================

@test "DRY-RUN-08: +cmd with \$HOME in config value → expanded in output" {
  write_config "{\"--add-dir\":\"\$HOME/.copilot/tools\"}"
  run_wrapper +cmd
  [ "$status" -eq 0 ]
  # Within run_wrapper, HOME is set to BATS_TMPDIR — envsubst should expand $HOME to that
  [[ "$output" == *"$BATS_TMPDIR/.copilot/tools"* ]]
  [[ "$output" != *'$HOME'* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# ENV-01: +env with config → prints COPILOT_ARGS value to stdout, stub not called
# ============================================================

@test "ENV-01: +env with config → prints COPILOT_ARGS value to stdout, stub not called" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +env
  [ "$status" -eq 0 ]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# ENV-02: +env with no config → prints empty string, stub not called
# ============================================================

@test "ENV-02: +env with no config → prints empty line, stub not called" {
  run_wrapper +env
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# VERBOSE-01: +verbose with config → prints [copilot-plus] cmd: line
# ============================================================

@test "VERBOSE-01: +verbose with config → output contains cmd line with copilot + flags" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"[copilot-plus] cmd:"* ]]
  [[ "$output" == *"copilot"* ]]
  [[ "$output" == *"--model"* ]]
  [[ "$output" == *"gpt-4.1"* ]]
  [[ "$output" == *"myarg"* ]]
}

# ============================================================
# VERBOSE-02: +verbose does NOT exit — copilot stub is called
# ============================================================

@test "VERBOSE-02: +verbose does NOT exit — stub is called normally" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# VERBOSE-03: +verbose output contains [copilot-plus] env: COPILOT_ARGS= line
# ============================================================

@test "VERBOSE-03: +verbose output contains [copilot-plus] env: COPILOT_ARGS= line" {
  write_config '{"--model":"gpt-4.1"}'
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [[ "$output" == *"[copilot-plus] env: COPILOT_ARGS="* ]]
}

# ============================================================
# VERBOSE-04: +verbose does not appear in args passed to copilot
# ============================================================

@test "VERBOSE-04: +verbose stripped from args forwarded to copilot" {
  run_wrapper +verbose myarg
  [ "$status" -eq 0 ]
  [ -f "$BATS_TMPDIR/stub_args" ]
  ! grep -qx "+verbose" "$BATS_TMPDIR/stub_args"
}

# ============================================================
# HELP-01: +help → prints help header, exit 0, stub not called
# ============================================================

@test "HELP-01: +help → prints 'copilot-plus + options:' header, exits 0, stub not called" {
  run_wrapper +help
  [ "$status" -eq 0 ]
  [[ "$output" == *"copilot-plus + options:"* ]]
  [ ! -f "$BATS_TMPDIR/stub_args" ]
}

# ============================================================
# HELP-02: +help output lists all four + option names
# ============================================================

@test "HELP-02: +help output lists +cmd, +env, +verbose, +help" {
  run_wrapper +help
  [ "$status" -eq 0 ]
  [[ "$output" == *"+cmd"* ]]
  [[ "$output" == *"+env"* ]]
  [[ "$output" == *"+verbose"* ]]
  [[ "$output" == *"+help"* ]]
}
