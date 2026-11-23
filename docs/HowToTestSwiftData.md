# Testing SwiftData: Patterns & Examples

These examples use the current app APIs and Swift Testing in the `studyAppTests`
target. Use the existing tests as the source of truth; this guide describes
patterns, not a passing test result for the current commit.

## Reuse the test fixtures

[TestContainer](../studyAppTests/StudyItems/Support/TestContainer.swift) and
[Fixtures](../studyAppTests/StudyItems/Support/Fixtures.swift) are available
throughout the unit-test target, despite living in the StudyItems folder.

- Create a fresh **container** for each test with `try TestContainer.makeContainer()`.
  A second context on the same container shares its store.
- The helper uses the full [AppSchema.models](../studyApp/App/AppSchema.swift)
  list, an in-memory store, CloudKit disabled and `mainContext.autosaveEnabled = false`.
  Reuse it as the model graph evolves instead of copying a partial schema.
- The helper retains containers because a context alone does not keep its
  container alive. `TestContainer.make()` is also available for tests that only
  need the writer context.
- `Fixtures` inserts models and connects relationships; it leaves saving to the
  test or the command under test.
- Use `@MainActor`, throwing test functions, `try` and `try #require(...)` so
  setup/fetch failures become test failures rather than forced-try crashes.

## Verify a ViewModel's save

A fetch on the writing context can see pending changes. For a save contract,
disable writer autosave, invoke the command and read through a fresh context
without adding a test-side save after the command. The fixture already disables
autosave on `mainContext`.

This complete example can be added to a Swift file in `studyAppTests`. The current
[SubjectsEditorVM](../studyApp/ViewModels/Settings/SubjectsEditorVM.swift) accepts
a nonempty name of at most 32 characters and a nonempty code of at most four.
Validation-only tests can instantiate the VM without any container.

```swift
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct SubjectPersistenceExamples {
    @Test("Adding a subject saves it and clears the form")
    func addingSubjectSaves() throws {
        let container = try TestContainer.makeContainer()
        let context = container.mainContext
        let vm = SubjectsEditorVM()
        vm.newSubjectName = "Physics"
        vm.newSubjectCode = "phys"
        #expect(vm.canAddSubject)

        vm.addSubject(context: context)

        let reader = ModelContext(container)
        let subjects = try reader.fetch(FetchDescriptor<Subject>())
        #expect(subjects.count == 1)
        let stored = try #require(subjects.first)
        #expect(stored.name == "Physics")
        #expect(stored.code == "PHYS")
        #expect(vm.newSubjectName.isEmpty)
        #expect(vm.newSubjectCode.isEmpty)
        #expect(!context.hasChanges)
    }
}
```

Use the same arrangement for a delete command: insert and explicitly save the
seed records, call the command, then fetch from a fresh context. A save between
the command and the reader could hide a missing save in the implementation.

## Use current session APIs and an injected clock

[StudyTrackingViewModel](../studyApp/ViewModels/StudyTrackingViewModel.swift)
owns session transitions. Use `startSession(context:)`, `pauseSession(context:)`,
`resumeSession(context:)` and `finishSession(context:)`. Sessions store
`startedAt` and optional `endedAt`; an unfinished record has `endedAt == nil`.
Advance the injected clock to test elapsed time deterministically.

```swift
import Foundation
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct SessionPersistenceExamples {
    @Test("Finishing saves the session and its closed section")
    func finishingSessionSaves() throws {
        let container = try TestContainer.makeContainer()
        let context = container.mainContext
        let subject = Fixtures.subject("Physics", in: context)
        try context.save() // Seed setup, before the commands under test.
        let subjectID = subject.id
        let start = Date(timeIntervalSinceReferenceDate: 1_000)
        var current = start
        let vm = StudyTrackingViewModel(now: { current })
        vm.selectSubject(subject)
        vm.startSession(context: context)
        let sessionID = try #require(vm.activeSessionID)
        current.addTimeInterval(60)

        vm.finishSession(context: context)

        let reader = ModelContext(container)
        let sessions = try reader.fetch(FetchDescriptor<StudySession>())
        #expect(sessions.count == 1)
        let stored = try #require(sessions.first)
        #expect(stored.id == sessionID)
        #expect(stored.startedAt == start)
        #expect(stored.endedAt == current)
        #expect(stored.subject?.id == subjectID)
        #expect(stored.subjectName == "Physics")
        #expect(stored.sections?.count == 1)
        #expect(stored.sections?.first?.endedAt == current)
        #expect(vm.activeSessionID == nil)
        #expect(vm.saveErrorMessage == nil)
        #expect(!context.hasChanges)
    }
}
```

See [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift),
particularly `completingSessionSavesGraph()`, for pause/resume, metadata, breaks
and location checks using a fresh reader with no extra save after completion.

## Save fixtures explicitly for model and query tests

When testing raw model persistence or a fetch descriptor, the test itself owns
the save. This example uses stored `FieldDefinition.order` for deterministic
ordering. SwiftData to-many relationship arrays are unordered; sort them
explicitly when checking display order.

```swift
import Foundation
import SwiftData
import Testing
@testable import studyApp

@MainActor
struct QueryExamples {
    @Test("Definitions filter and sort by their stored order")
    func definitionsFilterAndSort() throws {
        let container = try TestContainer.makeContainer()
        let context = container.mainContext
        for order in [2, 0, 1] {
            _ = Fixtures.definition("Field \(order)", order: order, in: context)
        }
        try context.save()

        let minimumOrder = 1
        let descriptor = FetchDescriptor<FieldDefinition>(
            predicate: #Predicate { $0.order >= minimumOrder },
            sortBy: [SortDescriptor(\FieldDefinition.order)]
        )
        let reader = ModelContext(container)
        let stored = try reader.fetch(descriptor)
        #expect(stored.map(\.order) == [1, 2])
    }
}
```

[StudyItemPersistenceTests](../studyAppTests/StudyItems/Store/StudyItemPersistenceTests.swift)
extends this pattern to all five field-content types, optional properties and
graphs. Use `try #require` before inspecting optional relationships or dates,
and compare explicit IDs/sets when order has no meaning.

## Test the declared relationship rules

Read the model's `@Relationship` declarations and assert both the removed rows
and the records that must survive. The current rules include:

| Delete | Expected result | Existing examples |
| --- | --- | --- |
| Subject | Sessions and items remain; their optional `subject` becomes `nil`, with `subjectName` retained. | `deletingSubjectPreservesHistory()` in [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift); `deletingSubjectKeepsItem()` in [StudyItemDeletionTests](../studyAppTests/StudyItems/Store/StudyItemDeletionTests.swift). |
| StudySession | Its breaks, sections and location cascade; its subject and unrelated records remain. | `deletingSessionsPreservesUnrelatedRecords(deleteAll:)` in [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift). |
| StudyItem or FieldDefinition | Owned field values cascade; shared records remain. | `deletingItemCascadesToValues()` and `deletingDefinitionCascadesToValues()` in [StudyItemDeletionTests](../studyAppTests/StudyItems/Store/StudyItemDeletionTests.swift). |
| Tag | Items and field values remain; their tag references clear. | `deletingTagNullifiesReferences()` in [StudyItemDeletionTests](../studyAppTests/StudyItems/Store/StudyItemDeletionTests.swift). |

Those examples have different scopes: some inspect the deleting context, and
`deletingSubjectPreservesHistory()` explicitly saves after its VM call. Use it
for relationship expectations; use the command/reader arrangement above when
the VM's own save is the behavior under test. For inverse checks, see
[StudyItemRelationshipTests](../studyAppTests/StudyItems/Model/StudyItemRelationshipTests.swift).

## Choose the persistence boundary

- **Same writer:** proves immediate model/VM state; pending changes may be visible.
- **Fresh context, same container:** checks a save into that store. The examples
  above use an isolated in-memory store.
- **Reopened disk container:** checks durable storage beyond one container's
  lifetime. `savedGraphAndDeletionSurviveReopeningStore()` in
  [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift) uses a
  unique temporary directory, deferred cleanup and scoped writers/readers so
  their models, contexts and containers are released before reopening.

Disk reopening covers neither an app-process relaunch nor a schema migration.
Use a dedicated temporary store for disk checks; keep the app's store isolated.

For the next explicitly authorized test run, open `studyApp.xcodeproj` in Xcode,
select the `studyApp` scheme and an available iOS simulator, then run the named
suite from the Test navigator. The [shared plan](../studyApp.xctestplan) includes
unit tests and disables UI tests. See [StudyItems verification](StudyItemTesting.md)
for existing check selection, evidence limits and manual relaunch checks.
App builds and test compilation require an explicit request under
[AGENTS.md](../AGENTS.md); source review alone does not establish that examples
compile or tests pass.
