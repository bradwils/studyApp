# StudyItems verification

The final suite uses the field-configuration implementation from #188 and #190.
It does not use the optional-value-slot APIs from the older V2 branch.

## Choosing an existing check

Use these sources to choose checks for the behavior being changed. Listed tests
describe coverage, not a passing result for the current commit.

| Change or failure | Existing check and scope |
| --- | --- |
| StudyItem defaults, field configuration, relationships or deletion | [StudyItem suites](../studyAppTests/StudyItems/): the retained coverage below; persistence reads use a fresh context in the same in-memory container, not a reopened disk store. |
| Session timing or transitions | [SessionTimingTests](../studyAppTests/SessionTimingTests.swift) and [StudySessionTests](../studyAppTests/StudySessionTests.swift): injected times, pause/resume, completion and countdown bounds. |
| Session saves, ownership or data loss | [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift): autosave disabled, fresh readers, active-session preservation and disk-store reopening. |
| Focus page selection or animation weights | [FocusPagerTests](../studyAppTests/FocusPagerTests.swift): page reconciliation, locking, overscroll and reduced motion; these do not render the UI. |
| Model/ViewModel layer imports | [SwiftLint rules](../.swiftlint.yml): prohibited imports fail lint; warnings do not fail the [CI job](../.github/workflows/swiftlint.yml). |
| TestFlight notes or PR build selection | [Python script tests](../ci_scripts/): `python3 -m unittest discover -s ci_scripts -p 'test*.py'`; these do not compile the app or prove delivery in Apple. |

The [shared test plan](../studyApp.xctestplan) disables UI tests. Use the manual
checks below for StudyItem editing and relaunch behavior, and consult
[pipeline.md](../pipeline.md) for current-head build/test evidence and promotion
checks. App builds and test compilation require the owner's explicit request,
as described in [AGENTS.md](../AGENTS.md).

## Retained coverage

| Suite | Behaviour checked |
| --- | --- |
| Defaults | Initial values, all field types/configurations, normalized tag keys |
| Relationships | Inverses for items, subjects, definitions and tags; field/tag reload |
| Persistence | All five content types, definition reconstruction, graphs and duplicate-tag reuse |
| Deletion | Cascades, nullification, shared records and the actual developer Delete All action |

Tests use the app's `AppSchema.models` list with in-memory storage, CloudKit off
and autosave disabled. Persistence assertions read through fresh contexts.
Deletion tests primarily inspect the deleting context; Delete All additionally
reads through a fresh context without an extra save, exercising the VM's save.
The existing session integrity tests from current `dev` remain included.

The older V2 tests in #183 were reviewed for transferable behaviour. The bulk-delete
regression is retained against the current VM, and field/tag deletion coverage is
extended. The payload-free slot tests do not apply to the selected model.

## Evidence

PR #190 records 35 unit tests passing on iPhone 17 / iOS 26.5 on 12 November 2026
at `407c4da`. That result predates the final integration and regression fixes.
It is not verification of the final head.

Final preparation uses source review, `git diff --check` and SwiftLint. No app
build or test compilation is run without the owner's explicit build request,
per the repository instructions. The added regression tests remain unexecuted.
The older V2 GitHub Actions run does not validate this implementation either.
Runner migration to Xcode Cloud remains separate work in #186.

## Manual checks for the next authorized run

- Open Debug Data and create a definition for each of the five field types.
- Create an item, attach fields, edit each value and confirm Updated advances.
- Enter repeated dropdown labels and check each choice appears once; remove a
  selected option and check the old selection remains visible.
- Complete an item, select Completed again, reopen it and complete it again;
  check the completion timestamp follows the documented transitions.
- Attach shared tags, delete a value, delete a tag and use Delete All; check
  unrelated items, definitions and tags survive as documented.
- Relaunch and confirm saved item data is retained.

Debug tooling still limits durations to ten hours in five-minute steps, hides
disabled fields and has no standalone orphan-value browser. These do not block
the SwiftData foundation in #134. Reinstall/reseed before these checks because
there is no versioned migration schema yet (#163).
