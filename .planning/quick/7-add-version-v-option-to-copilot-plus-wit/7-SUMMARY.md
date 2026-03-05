---
phase: quick
plan: 7
subsystem: copilot-plus
tags: [version, cli, bash]
key-files:
  modified: [copilot-plus]
decisions:
  - "VERSION variable placed on line 4, immediately after set -euo pipefail, for easy sed/auto-update"
  - "+version handler placed after +help block so help always prints even if combined with other flags"
metrics:
  duration: "3 min"
  completed: "2026-03-04"
  tasks: 1
  files: 1
---

# Quick Task 7: Add +version / +v Option Summary

**One-liner:** Added `VERSION="0.8.20260304"` and `+version`/`+v` flag to `copilot-plus` that prints `copilot-plus 0.8.20260304` and exits 0.

## What Was Changed

### `copilot-plus`

Four targeted edits to a single file:

1. **VERSION variable** (line 4, after `set -euo pipefail`):
   ```bash
   VERSION="0.8.20260304"
   ```

2. **`do_version=0` init** added alongside `do_cmd=0`, `do_env=0`, `do_verbose=0`, `do_help=0`.

3. **Arg-parse case block** — two new cases before `*)`:
   ```bash
   +version) do_version=1 ;;
   +v)       do_version=1 ;;
   ```

4. **`+help` output** updated with two new lines:
   ```bash
   printf '  +version  print version and exit\n'
   printf '  +v        alias for +version\n'
   ```

5. **Version handler** added after `+help` block:
   ```bash
   # +version / +v
   if [[ "$do_version" -eq 1 ]]; then
     printf 'copilot-plus %s\n' "$VERSION"
     exit 0
   fi
   ```

## Verification Results

```
$ bash copilot-plus +version
copilot-plus 0.8.20260304

$ bash copilot-plus +v
copilot-plus 0.8.20260304

$ bash copilot-plus +help | grep -E '\+version|\+v'
  +verbose  print command and COPILOT_ARGS, then run normally
  +version  print version and exit
  +v        alias for +version

$ head -10 copilot-plus | grep 'VERSION='
VERSION="0.8.20260304"
```

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1    | ff344f7 | feat(quick-7): add +version / +v option to copilot-plus |

## Self-Check: PASSED

- `copilot-plus` modified and committed ✓
- `bash copilot-plus +version` → `copilot-plus 0.8.20260304` ✓
- `bash copilot-plus +v` → `copilot-plus 0.8.20260304` ✓
- `+help` lists `+version` and `+v` ✓
- `VERSION=` on line 4 ✓
