---
phase: quick
plan: 8
type: execute
wave: 1
depends_on: []
files_modified: [copilot-plus]
autonomous: true
requirements: [QUICK-8]

must_haves:
  truths:
    - "++cmd and +c both print the command and exit"
    - "++env and +e both print COPILOT_ARGS and exit"
    - "++verbose and +V both print diagnostics then run"
    - "++help and +h both show updated help text"
    - "++version and +v both print the version and exit"
    - "Old +word forms (e.g. +cmd, +env, +verbose, +help, +version) are no longer recognized"
  artifacts:
    - path: "copilot-plus"
      provides: "Updated option parsing with ++word / +char convention"
      contains: "++cmd"
  key_links:
    - from: "case statement in copilot-plus"
      to: "do_* flag variables"
      via: "pattern arms for ++word and +char"
      pattern: "\\+\\+cmd|\\+c\\)"
---

<objective>
Refactor `copilot-plus` + options from the current `+word` single-form convention to the
`++word` (long) / `+<char>` (short) convention, matching standard CLI idiom.

Purpose: Consistency with `-v`/`--verbose` style; old `+word` forms removed (personal tool, clean break).
Output: Updated `copilot-plus` with new option syntax throughout.
</objective>

<execution_context>
@/home/cavanaug/.copilot/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.copilot/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<!-- Key mapping for this refactor:
  Old        → New long    / New short
  +cmd       → ++cmd       / +c
  +env       → ++env       / +e
  +verbose   → ++verbose   / +V   (capital V; +v is taken by version)
  +help      → ++help      / +h
  +version   → ++version   / +v   (keeps existing +v alias)
-->
</context>

<tasks>

<task type="auto">
  <name>Task 1: Replace + option handling in copilot-plus</name>
  <files>copilot-plus</files>
  <action>
Make the following targeted edits to `copilot-plus`:

**1. Case statement (lines ~157-165) — replace entire option-parsing block:**

Old:
```bash
  case "$arg" in
    +cmd)     do_cmd=1 ;;
    +env)     do_env=1 ;;
    +verbose) do_verbose=1 ;;
    +help)    do_help=1 ;;
    +version) do_version=1 ;;
    +v)       do_version=1 ;;
    *)        user_args+=("$arg") ;;
  esac
```

New:
```bash
  case "$arg" in
    ++cmd|+c)      do_cmd=1 ;;
    ++env|+e)      do_env=1 ;;
    ++verbose|+V)  do_verbose=1 ;;
    ++help|+h)     do_help=1 ;;
    ++version|+v)  do_version=1 ;;
    *)             user_args+=("$arg") ;;
  esac
```

**2. Section comment above the case statement (line ~149):**

Old:  `# Parse + options from user args; strip them before passing to copilot`
New:  `# Parse ++ / + options from user args; strip them before passing to copilot`

**3. Help output block (lines ~170-177) — replace all printf lines:**

Old:
```bash
  printf 'copilot-plus + options:\n'
  printf '  +cmd      print the command that would be run, then exit\n'
  printf '  +env      print COPILOT_ARGS value, then exit\n'
  printf '  +verbose  print command and COPILOT_ARGS, then run normally\n'
  printf '  +help     show this help\n'
  printf '  +version  print version and exit\n'
  printf '  +v        alias for +version\n'
```

New:
```bash
  printf 'copilot-plus ++ options:\n'
  printf '  ++cmd,     +c  print the command that would be run, then exit\n'
  printf '  ++env,     +e  print COPILOT_ARGS value, then exit\n'
  printf '  ++verbose, +V  print command and COPILOT_ARGS, then run normally\n'
  printf '  ++help,    +h  show this help\n'
  printf '  ++version, +v  print version and exit\n'
```

**4. Handler-block comments — update inline comments:**

- `# +help (check first so it works even with bad args)`  →  `# ++help / +h (check first so it works even with bad args)`
- `# +version / +v`  →  `# ++version / +v`
- `# +cmd: print command and exit`  →  `# ++cmd / +c: print command and exit`
- `# +env: print COPILOT_ARGS and exit`  →  `# ++env / +e: print COPILOT_ARGS and exit`
- `# +verbose: print diagnostics, then fall through to exec (intentionally no exit)`  →  `# ++verbose / +V: print diagnostics, then fall through to exec (intentionally no exit)`
  </action>
  <verify>
    <automated>
      # Confirm new long forms are present
      grep -q '++cmd' copilot-plus && echo "++cmd OK" || echo "FAIL: ++cmd missing"
      grep -q '++env' copilot-plus && echo "++env OK" || echo "FAIL: ++env missing"
      grep -q '++verbose' copilot-plus && echo "++verbose OK" || echo "FAIL: ++verbose missing"
      grep -q '++help' copilot-plus && echo "++help OK" || echo "FAIL: ++help missing"
      grep -q '++version' copilot-plus && echo "++version OK" || echo "FAIL: ++version missing"
      # Confirm short forms are present
      grep -q '+c)' copilot-plus && echo "+c OK" || echo "FAIL: +c missing"
      grep -q '+e)' copilot-plus && echo "+e OK" || echo "FAIL: +e missing"
      grep -q '+V)' copilot-plus && echo "+V OK" || echo "FAIL: +V missing"
      grep -q '+h)' copilot-plus && echo "+h OK" || echo "FAIL: +h missing"
      # Confirm old bare +word forms are gone from case statement (they may still appear in comments)
      grep -P '^\s+\+cmd\)' copilot-plus && echo "FAIL: old +cmd) still in case" || echo "old +cmd gone OK"
      grep -P '^\s+\+env\)' copilot-plus && echo "FAIL: old +env) still in case" || echo "old +env gone OK"
      grep -P '^\s+\+verbose\)' copilot-plus && echo "FAIL: old +verbose) still in case" || echo "old +verbose gone OK"
      grep -P '^\s+\+help\)' copilot-plus && echo "FAIL: old +help) still in case" || echo "old +help gone OK"
      # Functional smoke test
      bash copilot-plus +h 2>&1 | grep -q '++help' && echo "+h functional OK" || echo "FAIL: +h output wrong"
      bash copilot-plus ++help 2>&1 | grep -q '++help' && echo "++help functional OK" || echo "FAIL: ++help output wrong"
      bash copilot-plus +v 2>&1 | grep -q 'copilot-plus' && echo "+v functional OK" || echo "FAIL: +v output wrong"
      bash copilot-plus ++version 2>&1 | grep -q 'copilot-plus' && echo "++version functional OK" || echo "FAIL: ++version output wrong"
    </automated>
  </verify>
  <done>
    - All `++word` long forms and `+char` short forms present in case statement
    - Old bare `+word)` case arms removed
    - Help output shows new `++word, +char` format (no old `+v alias for +version` line)
    - All handler-block comments updated
    - `bash copilot-plus +h` shows `++help` in output
    - `bash copilot-plus ++version` and `+v` both print version
  </done>
</task>

</tasks>

<verification>
Run the automated verify block above. All lines should end in `OK`, none in `FAIL`.

Also confirm the help output looks correct:
```
bash copilot-plus ++help
```
Expected output:
```
copilot-plus ++ options:
  ++cmd,     +c  print the command that would be run, then exit
  ++env,     +e  print COPILOT_ARGS value, then exit
  ++verbose, +V  print command and COPILOT_ARGS, then run normally
  ++help,    +h  show this help
  ++version, +v  print version and exit
```
</verification>

<success_criteria>
- `++cmd`, `++env`, `++verbose`, `++help`, `++version` all recognized and functional
- `+c`, `+e`, `+V`, `+h`, `+v` all recognized and functional
- Old `+cmd`, `+env`, `+verbose`, `+help`, `+version` bare forms NOT recognized (passed through as user args)
- Help text reflects new convention with aligned columns
</success_criteria>

<output>
After completion, create `.planning/quick/8-refactor-options-to-use-char-short-form-/8-SUMMARY.md`
</output>
