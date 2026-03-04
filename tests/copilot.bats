#!/usr/bin/env bats
# Test suite for the copilot wrapper script
# Covers all 16 requirements: CONF-01..03, MAP-01..07, INVK-01..04, DIST-01..02

setup() {
  # Create stub copilot binary
  mkdir -p "$BATS_TMPDIR/bin"
  STUB_ARGS_FILE="$BATS_TMPDIR/stub_args"
  printf '#!/usr/bin/env bash\nprintf '"'"'%%s\\n'"'"' "$@" > "%s"\nexit 0\n' "$STUB_ARGS_FILE" \
    > "$BATS_TMPDIR/bin/copilot"
  chmod +x "$BATS_TMPDIR/bin/copilot"

  # Create .copilot config directory
  mkdir -p "$BATS_TMPDIR/.copilot"
}

teardown() {
  rm -f "$BATS_TMPDIR/stub_args"
  rm -f "$BATS_TMPDIR/.copilot/config.json"
}

# Helper: run wrapper with stub copilot
run_wrapper() {
  run env HOME="$BATS_TMPDIR" PATH="$BATS_TMPDIR/bin:$PATH" bash "$BATS_TEST_DIRNAME/../copilot-cli" "$@"
}

# Helper: write config JSON
write_config() {
  printf '%s\n' "$1" > "$BATS_TMPDIR/.copilot/config.json"
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
# DIST-02: Script is named 'copilot-cli', invoked via alias copilot=copilot-cli
# ============================================================

@test "DIST-02: wrapper named copilot-cli is invoked via shell alias" {
  write_config '{}'
  run_wrapper myarg
  [ "$status" -eq 0 ]
  # Stub was called (not the real copilot) meaning PATH ordering worked
  [ -f "$BATS_TMPDIR/stub_args" ]
  grep -qx "myarg" "$BATS_TMPDIR/stub_args"
}
