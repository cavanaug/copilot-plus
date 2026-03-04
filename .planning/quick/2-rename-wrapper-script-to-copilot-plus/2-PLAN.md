---
quick: 2
type: execute
wave: 1
depends_on: []
files_modified:
  - copilot-plus           # renamed from copilot-cli
  - tests/copilot.bats
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
autonomous: true
requirements: [DIST-02]

must_haves:
  truths:
    - "File `copilot-plus` exists and `copilot-cli` does not"
    - "All 37 bats tests pass after rename"
    - "Error messages inside the script say `copilot-plus:` not `copilot-wrapper:`"
    - "Users can invoke via `alias copilot=copilot-plus`"
  artifacts:
    - path: "copilot-plus"
      provides: "The renamed wrapper script"
    - path: "tests/copilot.bats"
      provides: "Test suite referencing ../copilot-plus and updated DIST-02 description"
  key_links:
    - from: "tests/copilot.bats run_wrapper helpers"
      to: "copilot-plus"
      via: "bash \"$BATS_TEST_DIRNAME/../copilot-plus\""
---

<objective>
Rename the wrapper script from `copilot-cli` to `copilot-plus` and update all references so all 37 bats tests continue to pass.

Purpose: Align the script name with the project's branding (`copilot-plus`).
Output: `copilot-plus` script, updated test file, updated planning docs.
</objective>

<execution_context>
@/home/cavanaug/.config/opencode.gsd/get-shit-done/workflows/execute-plan.md
@/home/cavanaug/.config/opencode.gsd/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/REQUIREMENTS.md
@.planning/ROADMAP.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Git-rename script and update internal references</name>
  <files>copilot-plus (renamed from copilot-cli)</files>
  <action>
    1. `git mv copilot-cli copilot-plus` — preserves git history via rename detection.
    2. Inside `copilot-plus`, replace the two error-message prefixes:
       - `copilot-wrapper: error:` → `copilot-plus: error:`
       (Lines 57, 90, 101 — all three `echo "copilot-wrapper: error:` occurrences)
    3. No other internal logic changes needed — the script does not reference its own filename.
  </action>
  <verify>
    <automated>git status --short | grep -E "^R.*copilot-cli.*copilot-plus" && grep -c "copilot-plus:" copilot-plus</automated>
  </verify>
  <done>`copilot-cli` no longer exists; `copilot-plus` exists with `copilot-plus:` in all error messages; `git mv` rename is staged.</done>
</task>

<task type="auto">
  <name>Task 2: Update tests and planning docs, then verify all 37 tests pass</name>
  <files>tests/copilot.bats, .planning/REQUIREMENTS.md, .planning/ROADMAP.md</files>
  <action>
    **tests/copilot.bats** — four kinds of changes:
    1. `run_wrapper` helper (line 27): `../copilot-cli` → `../copilot-plus`
    2. `run_wrapper_in_project` helper (line 33): `../copilot-cli` → `../copilot-plus`
    3. `run_wrapper_in_subdir` helper (line 493): `../copilot-cli` → `../copilot-plus`
    4. Inline bare references (lines 541, 555): `../copilot-cli` → `../copilot-plus`
    5. DIST-02 test description (line 276 comment + line 279 @test name):
       - Comment: `# DIST-02: Script is named 'copilot-cli', invoked via alias copilot=copilot-cli`
         → `# DIST-02: Script is named 'copilot-plus', invoked via alias copilot=copilot-plus`
       - @test name: `"DIST-02: wrapper named copilot-cli is invoked via shell alias"`
         → `"DIST-02: wrapper named copilot-plus is invoked via shell alias"`

    **Use `replaceAll` (sed-style):** replace every occurrence of `../copilot-cli` with `../copilot-plus` in the file, then update the DIST-02 strings above.

    **.planning/REQUIREMENTS.md** — line 34 (DIST-02):
    - `Script is named \`copilot-cli\` and intended to be invoked via shell alias \`alias copilot=copilot-cli\``
      → `Script is named \`copilot-plus\` and intended to be invoked via shell alias \`alias copilot=copilot-plus\``

    **.planning/ROADMAP.md** — no `copilot-cli` appears in the body text (only in the title `copilot-cli-wrapper` which is a project name, not the script name — leave it unchanged).

    After all edits, run the full test suite and confirm all 37 tests pass:
    ```
    cd /home/cavanaug/wip_other/projects/copilot-cli
    bats tests/copilot.bats
    ```
  </action>
  <verify>
    <automated>bats tests/copilot.bats 2>&1 | tail -5</automated>
  </verify>
  <done>
    - `tests/copilot.bats` contains zero references to `../copilot-cli`
    - DIST-02 test name and comment mention `copilot-plus`
    - REQUIREMENTS.md DIST-02 line references `copilot-plus`
    - `bats tests/copilot.bats` reports 37 tests, 0 failures
  </done>
</task>

</tasks>

<verification>
```bash
# 1. Script renamed correctly
ls copilot-plus && ! ls copilot-cli 2>/dev/null

# 2. No stale copilot-cli references in active source files
grep -r "copilot-cli" copilot-plus tests/copilot.bats .planning/REQUIREMENTS.md 2>/dev/null && echo "STALE REFS FOUND" || echo "clean"

# 3. All tests pass
bats tests/copilot.bats
```
</verification>

<success_criteria>
- `copilot-plus` exists; `copilot-cli` is gone from the working tree
- `grep -r "copilot-cli" copilot-plus tests/copilot.bats .planning/REQUIREMENTS.md` returns nothing
- `bats tests/copilot.bats` → 37 tests, 0 failures
- Error messages inside the script use `copilot-plus:` prefix
</success_criteria>

<output>
After completion, create `.planning/quick/2-rename-wrapper-script-to-copilot-plus/2-SUMMARY.md`
</output>
