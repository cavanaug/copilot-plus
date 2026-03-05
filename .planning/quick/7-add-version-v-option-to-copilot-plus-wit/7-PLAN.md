---
phase: quick
plan: 7
type: execute
wave: 1
depends_on: []
files_modified: [copilot-plus]
autonomous: true
requirements: [QUICK-7]
must_haves:
  truths:
    - "Running `copilot-plus +version` prints `copilot-plus 0.8.20260304` and exits 0"
    - "Running `copilot-plus +v` behaves identically to `+version`"
    - "`+help` output includes entries for `+version` and `+v`"
    - "VERSION is defined in a single line near the top of the script for easy auto-update"
  artifacts:
    - path: "copilot-plus"
      provides: "Main script with VERSION variable and +version/+v option"
      contains: "VERSION="
  key_links:
    - from: "+version/+v flag parse block"
      to: "VERSION variable"
      via: "do_version flag → printf 'copilot-plus $VERSION'"
---

<objective>
Add `+version` and `+v` options to the `copilot-plus` bash script.

Purpose: Allow users and tooling to query the script version without running a full copilot invocation.
Output: Modified `copilot-plus` with `VERSION="0.8.20260304"` near the top, `+version`/`+v` parsing, version print-and-exit behavior, and updated `+help` output.
</objective>

<execution_context>
@/home/cavanaug/.copilot/get-shit-done/workflows/execute-plan.md
</execution_context>

<context>
@copilot-plus
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add VERSION variable and +version/+v option</name>
  <files>copilot-plus</files>
  <action>
Make three targeted edits to `copilot-plus`:

**Edit 1 — Add VERSION near the top** (after the shebang/set line, before GLOBAL_CONFIG):
Insert immediately after line 3 (`set -euo pipefail`):
```bash

VERSION="0.8.20260304"
```

**Edit 2 — Add +version/+v to the arg-parse case block** (lines 154-160):
Add two new cases before the `*)` catch-all:
```bash
    +version) do_version=1 ;;
    +v)       do_version=1 ;;
```
Also add `do_version=0` to the initializations block above the `for` loop (alongside `do_cmd=0`, `do_env=0`, etc.).

**Edit 3 — Add version handler** after the `+help` block (after `exit 0` on line 171), before the `print_cmd` helper comment:
```bash
# +version / +v
if [[ "$do_version" -eq 1 ]]; then
  printf 'copilot-plus %s\n' "$VERSION"
  exit 0
fi
```

**Edit 4 — Update +help output** to include the two new entries (insert after the `+help` line in the printf block):
```bash
  printf '  +version  print version and exit\n'
  printf '  +v        alias for +version\n'
```
Add these two lines immediately after the `+help     show this help` printf line and before `exit 0`.
  </action>
  <verify>
    <automated>
cd /home/cavanaug/wip_other/projects/copilot-plus
bash copilot-plus +version
bash copilot-plus +v
bash copilot-plus +help | grep -E '\+version|\+v'
    </automated>
  </verify>
  <done>
- `bash copilot-plus +version` prints `copilot-plus 0.8.20260304` and exits 0
- `bash copilot-plus +v` prints `copilot-plus 0.8.20260304` and exits 0
- `bash copilot-plus +help` output includes `+version` and `+v` entries
- `grep VERSION copilot-plus` shows `VERSION="0.8.20260304"` near the top of the file
  </done>
</task>

</tasks>

<verification>
```bash
cd /home/cavanaug/wip_other/projects/copilot-plus
# Version flag works
bash copilot-plus +version | grep -E '^copilot-plus 0\.8\.[0-9]+$'
bash copilot-plus +v       | grep -E '^copilot-plus 0\.8\.[0-9]+$'
# Help shows new entries
bash copilot-plus +help | grep '+version'
bash copilot-plus +help | grep '+v'
# VERSION line is near the top (within first 10 lines)
head -10 copilot-plus | grep 'VERSION='
# Script still passes shellcheck (if available)
shellcheck copilot-plus 2>/dev/null || true
```
</verification>

<success_criteria>
- `+version` and `+v` both print `copilot-plus 0.8.20260304` and exit 0
- `+help` lists both `+version` and `+v` with descriptions
- `VERSION="0.8.20260304"` appears as a single, top-of-script line (easy to sed/auto-update)
- All existing `+cmd`, `+env`, `+verbose`, `+help` options still work unchanged
</success_criteria>

<output>
After completion, create `.planning/quick/7-add-version-v-option-to-copilot-plus-wit/7-SUMMARY.md` with what was changed and the final VERSION value.
</output>
