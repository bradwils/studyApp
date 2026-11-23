# StudyItems verification

The final suite uses the field-configuration implementation from #188 and #190.
It does not use the optional-value-slot APIs from the older V2 branch.

## Choosing an existing check

| Change or failure | Where to check |
| --- | --- |
| StudyItem fields, relationships or deletion | [StudyItem suites](../studyAppTests/StudyItems/) exercise the model graph and read saved values from a fresh context in the same in-memory container. |
| Session timing or transitions | [SessionTimingTests](../studyAppTests/SessionTimingTests.swift) and [StudySessionTests](../studyAppTests/StudySessionTests.swift) cover pause, resume, completion and countdown bounds with controlled dates. |
| Session saves, ownership or data loss | [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift) disables autosave, reads through fresh contexts, checks active-session preservation and reopens a disk store. |
| Focus page selection or animation weights | [FocusPagerTests](../studyAppTests/FocusPagerTests.swift) exercises page reconciliation, locking, overscroll and reduced motion. |
| Model and ViewModel imports | The [SwiftLint config](../.swiftlint.yml) defines the layer rules. Errors fail the [CI job](../.github/workflows/swiftlint.yml). |
| TestFlight notes or PR build selection | Run the [Python suites](../ci_scripts/) with `python3 -m unittest discover -s ci_scripts -p 'test*.py'`. |

The [shared test plan](../studyApp.xctestplan) disables UI tests. The manual checks
below cover editing and relaunch behavior. [The pipeline](../pipeline.md) lists
the evidence to collect for promotion, and [AGENTS.md](../AGENTS.md) describes
when to run an app build.

## Retained coverage

| Suite | Behaviour checked |
| --- | --- |
| Defaults | Initial values, all field types/configurations, normalized tag keys |
| Relationships | Inverses for items, subjects, definitions and tags; field/tag reload |
| Persistence | All five content types, definition reconstruction, shared tags and field ordering |
| Deletion | Cascades, nullification, shared records and deleting all items individually |

Tests use the app's `AppSchema.models` list with in-memory storage, CloudKit off
and autosave disabled. The round-trip tests fetch through a fresh context.
Most deletion tests inspect the deleting context. X7 deletes each fetched item
and explicitly saves before a fresh reader checks which records survived.
The manual Delete All check below exercises the editor action itself.

## Editing regressions

[StudyItemEditingTests](../studyAppTests/StudyItems/StudyItemEditingTests.swift)
calls the actual developer VM for completion, repeated status selection,
reopening, re-completion, subject assignment/clearing and all five content types.
Historical timestamp markers verify updates and no-ops without sleeps.

Field attachment reads through fresh contexts without an extra save after the VM
call; duplicate attachment must retain the existing value, content and edit date.
Status, subject and content methods do not save, so their assertions inspect the
edited models. These tests do not render SwiftUI bindings or cover relaunch.

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
