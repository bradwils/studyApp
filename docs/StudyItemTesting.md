# StudyItems verification

The final suite uses the field-configuration implementation from #188 and #190.
It does not use the optional-value-slot APIs from the older V2 branch.

## Retained coverage

| Suite | Behaviour checked |
| --- | --- |
| Defaults | Initial values, all field types/configurations, normalized tag keys |
| Relationships | Inverses for items, subjects, definitions and tags; field/tag reload |
| Persistence | All five content types, definition reconstruction, graphs and duplicate-tag reuse |
| Deletion | Cascades, nullification, shared records and the actual developer Delete All action |
| Editing regressions | Completion/reopening, custom-content timestamps, duplicate values and dropdown normalization/type locking |

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
