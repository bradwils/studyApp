# StudyItems V2 verification

V2 stores text/dropdown, number, date and duration values in ordinary optional
properties on `FieldValue`. `FieldDefinition.kind` selects the active property;
the model does not clear inactive properties automatically. Keep this structure
while validating its persistence and relationships.

## Tests

`studyAppTests/StudyItems/` exercises V2's current API. Persistence assertions
fetch through a fresh `ModelContext` after saving, so cached instances cannot
stand in for a store round trip. Containers are isolated and in memory.

The `StudyItems unit tests` GitHub Actions workflow runs the unit-test target on
an iPhone simulator with Xcode 26.6. It is scoped to the V2 feature and test
branches, including PRs into `Study-items-V2`. It does not archive or distribute
the app; those builds remain in Xcode Cloud. Results and logs are attached to
the workflow run for seven days. A green run is required before merging the
test branch; unexecuted source review is not equivalent to passing tests.

To run locally, select an available iOS 26-or-newer simulator in Xcode or run:

```sh
xcodebuild test -project studyApp.xcodeproj -scheme studyApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:studyAppTests
```

The old draft #168 uses removed payload enums and ordering APIs. Do not merge
it unchanged or apply tests that silently assume the old design.

## Debug inspection and remaining decisions

Debug Data already includes editors for items, definitions and tags, with
controls for all five field kinds. Definition kind is locked after creation.
Current controls do not inspect inactive storage properties or clear optional
values back to nil, hide disabled definitions, and limit duration input to ten
hours in five-minute increments. Metadata is read-only; standalone/orphaned
field values do not have their own root browser.

The review on #170 records duplicate dropdown-option identities and custom
value edits that do not touch the parent item's `updatedAt`. These can be fixed
in validation/editing without redesigning the persisted structure. Status-change
semantics for `completedAt` remain the explicit `TODO(human)` decision. Versioned
schema/migration work (#163) remains deferred until the feature settles.
