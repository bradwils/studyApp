# Testing SwiftData: Patterns & Examples

This guide shows how to write tests for SwiftData models and ViewModels using in-memory containers for isolation and speed.

---

## Foundation: Test Helper

Create `TestHelpers.swift` in your test bundle. This is reusable across all tests.

```swift
import Foundation
import SwiftData
import XCTest

/// Creates an in-memory SwiftData container for testing.
/// Use this in setUp() for every test to ensure isolation and speed.
func createTestModelContainer() -> ModelContainer {
    // isStoredInMemoryOnly: true means data is NOT saved to disk.
    // Each test gets a fresh, empty database. Tests don't interfere.
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    
    // Include ALL models your app uses (or just the ones being tested).
    // SwiftData needs to know about every @Model you'll persist.
    return try! ModelContainer(
        for: Subject.self, StudySession.self, StudyGroup.self,
        configurations: [config]
    )
}

/// Creates a ModelContext from a test container.
/// Use this to insert/query data in your tests.
func createTestContext(container: ModelContainer? = nil) -> ModelContext {
    let container = container ?? createTestModelContainer()
    return ModelContext(container)
}
```

**Why?**
- `isStoredInMemoryOnly: true` keeps tests fast (no disk I/O) and isolated (no real data touched)
- Fresh container per test = no test pollution (test A's data doesn't affect test B)
- Centralizing this helper means you change it once if SwiftData patterns shift

---

## Example 1: Testing a ViewModel's CRUD Logic

Let's test `SubjectsEditorVM` (add, remove, validation).

```swift
import XCTest
@testable import studyApp

class SubjectsEditorVMTests: XCTestCase {
    // Set up fresh ViewModel and context for each test
    var vm: SubjectsEditorVM!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        // Fresh context = fresh database for this test
        context = createTestContext()
        // Initialize ViewModel (it holds UI state, not persistence logic)
        vm = SubjectsEditorVM()
    }
    
    // MARK: - Validation Tests (no database needed)
    
    /// Test that canAddSubject is false when form is empty.
    /// Validation logic doesn't touch the database—test it in isolation.
    func testCanAddSubjectWhenEmpty() {
        XCTAssertFalse(vm.canAddSubject, "canAddSubject should be false initially")
    }
    
    /// Test that form state updates as user types.
    /// This tests the ViewModel's UI state tracking.
    func testCanAddSubjectWhenNameProvided() {
        vm.newSubjectName = "Mathematics"
        // Code is still empty, so canAddSubject should still be false
        XCTAssertFalse(vm.canAddSubject, "canAddSubject is false without code")
        
        vm.newSubjectCode = "MATH101"
        // Now both fields are filled
        XCTAssertTrue(vm.canAddSubject, "canAddSubject is true when both fields filled")
    }
    
    // MARK: - Persistence Tests (uses ModelContext)
    
    /// Test that addSubject saves to the database.
    /// ViewModel method accepts context as a parameter (dependency injection).
    /// We verify by querying the database afterward.
    func testAddSubjectSavesToDatabase() {
        // Set up the form
        vm.newSubjectName = "Physics"
        vm.newSubjectCode = "PHYS101"
        
        // Call the ViewModel method, passing the test context
        vm.addSubject(context: context)
        
        // Verify it was actually saved: fetch all subjects
        let descriptor = FetchDescriptor<Subject>()
        let allSubjects = try! context.fetch(descriptor)
        XCTAssertEqual(allSubjects.count, 1, "Should have inserted one subject")
        XCTAssertEqual(allSubjects[0].name, "Physics", "Saved subject should have correct name")
        XCTAssertEqual(allSubjects[0].code, "PHYS101", "Saved subject should have correct code")
    }
    
    /// Test that the form clears after successful add.
    /// This is ViewModel behavior: after saving, reset the UI fields.
    func testAddSubjectClearsForm() {
        vm.newSubjectName = "Chemistry"
        vm.newSubjectCode = "CHEM101"
        
        vm.addSubject(context: context)
        
        // Form should be reset so user can add another subject
        XCTAssertEqual(vm.newSubjectName, "", "newSubjectName should be cleared")
        XCTAssertEqual(vm.newSubjectCode, "", "newSubjectCode should be cleared")
    }
    
    /// Test that removing a subject deletes it from the database.
    /// Verify using a fetch afterward.
    func testRemoveSubjectDeletesFromDatabase() {
        // First, add a subject to remove
        let newSubject = Subject(name: "Biology", code: "BIO101")
        context.insert(newSubject)
        try! context.save()
        
        // Verify it exists
        var descriptor = FetchDescriptor<Subject>()
        var subjects = try! context.fetch(descriptor)
        XCTAssertEqual(subjects.count, 1)
        
        // Remove via ViewModel
        vm.removeSubject(newSubject, context: context)
        
        // Verify it's gone
        subjects = try! context.fetch(descriptor)
        XCTAssertEqual(subjects.count, 0, "Subject should be deleted")
    }
}
```

**Key Patterns:**
- **Fresh context per test:** `setUp()` creates a clean database
- **Dependency injection:** Pass `context` to ViewModel methods; ViewModel doesn't store it
- **Fetch to verify:** After calling ViewModel methods, query the database to confirm persistence
- **Validation without DB:** Test computed properties (`canAddSubject`) without touching the database—they're just Swift logic

---

## Example 2: Testing with Predicates & Filtering

SwiftData queries use predicates for filtering. Test that your queries return the right data.

```swift
class StudySessionVMTests: XCTestCase {
    var vm: StudySessionVM!
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        context = createTestContext()
        vm = StudySessionVM()
    }
    
    /// Test that fetching today's sessions filters correctly.
    /// Predicates are how you ask "give me only sessions from today".
    func testFetchTodaysSessions() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Insert sessions across different dates
        let todaySession = StudySession(subject: "Math", startTime: today, duration: 30)
        let tomorrowSession = StudySession(subject: "Physics", startTime: tomorrow, duration: 45)
        let yesterdaySession = StudySession(subject: "Chemistry", startTime: yesterday, duration: 20)
        
        context.insert(todaySession)
        context.insert(tomorrowSession)
        context.insert(yesterdaySession)
        try! context.save()
        
        // Fetch only today's sessions using a predicate.
        // The #Predicate macro is SwiftData's type-safe way to filter.
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { session in
                session.startTime >= startOfDay && session.startTime < endOfDay
            }
        )
        let todaysSessions = try! context.fetch(descriptor)
        
        XCTAssertEqual(todaysSessions.count, 1, "Should fetch only today's session")
        XCTAssertEqual(todaysSessions[0].subject, "Math")
    }
    
    /// Test sorting: verify sessions are returned in the order you expect.
    /// The sort parameter in FetchDescriptor controls order.
    func testSessionsSortedByDurationDescending() {
        let session1 = StudySession(subject: "Math", startTime: Date(), duration: 30)
        let session2 = StudySession(subject: "Physics", startTime: Date(), duration: 60)
        let session3 = StudySession(subject: "Chemistry", startTime: Date(), duration: 15)
        
        context.insert(session1)
        context.insert(session2)
        context.insert(session3)
        try! context.save()
        
        // FetchDescriptor with sort: descending by duration
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\StudySession.duration, order: .reverse)]
        )
        let sorted = try! context.fetch(descriptor)
        
        // Verify order: longest first
        XCTAssertEqual(sorted[0].duration, 60)
        XCTAssertEqual(sorted[1].duration, 30)
        XCTAssertEqual(sorted[2].duration, 15)
    }
    
    /// Test combining predicate and sort.
    /// You often need both: filter AND order the results.
    func testFetchActiveSessionsSortedByRecency() {
        let now = Date()
        
        let activeRecent = StudySession(subject: "Math", startTime: now, duration: 45, isActive: true)
        let activeOld = StudySession(subject: "Physics", startTime: Calendar.current.date(byAdding: .day, value: -1, to: now)!, duration: 30, isActive: true)
        let inactiveRecent = StudySession(subject: "Chemistry", startTime: now, duration: 60, isActive: false)
        
        context.insert(activeRecent)
        context.insert(activeOld)
        context.insert(inactiveRecent)
        try! context.save()
        
        // Fetch active sessions, sorted newest first
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\StudySession.startTime, order: .reverse)]
        )
        let results = try! context.fetch(descriptor)
        
        XCTAssertEqual(results.count, 2, "Should fetch 2 active sessions")
        XCTAssertEqual(results[0].subject, "Math", "Newest active should be first")
        XCTAssertEqual(results[1].subject, "Physics")
    }
}
```

**Key Patterns:**
- **#Predicate macro:** Type-safe way to filter data. Compiler checks your logic.
- **SortDescriptor:** Controls the order of results (ascending/descending)
- **Combined:** Use both predicate and sort together for complex queries
- **Verify with assertions:** Check count and order to confirm the query works as expected

---

## Example 3: Testing Relationships

If your models have relationships (e.g., Subject has many StudySessions), test that associations work.

```swift
class StudySessionRelationshipTests: XCTestCase {
    var context: ModelContext!
    
    override func setUp() {
        super.setUp()
        context = createTestContext()
    }
    
    /// Test that creating a session linked to a subject works.
    /// Relationships are how models reference each other in SwiftData.
    func testSessionLinkedToSubject() {
        let subject = Subject(name: "Mathematics", code: "MATH101")
        let session = StudySession(subject: subject, duration: 45)
        
        context.insert(subject)
        context.insert(session)
        try! context.save()
        
        // Fetch the session and verify the relationship is intact
        let descriptor = FetchDescriptor<StudySession>()
        let sessions = try! context.fetch(descriptor)
        
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].subject.name, "Mathematics", "Session should reference correct subject")
    }
    
    /// Test cascade delete: if a subject is deleted, related sessions are also deleted.
    /// This depends on your @Relationship configuration (e.g., deleteRule: .cascade).
    func testDeleteSubjectCascadesToSessions() {
        let subject = Subject(name: "Physics", code: "PHYS101")
        let session = StudySession(subject: subject, duration: 60)
        
        context.insert(subject)
        context.insert(session)
        try! context.save()
        
        // Verify both exist
        var subjectDescriptor = FetchDescriptor<Subject>()
        var sessionDescriptor = FetchDescriptor<StudySession>()
        XCTAssertEqual(try! context.fetch(subjectDescriptor).count, 1)
        XCTAssertEqual(try! context.fetch(sessionDescriptor).count, 1)
        
        // Delete the subject
        context.delete(subject)
        try! context.save()
        
        // If cascade is configured, the session should also be gone
        XCTAssertEqual(try! context.fetch(subjectDescriptor).count, 0)
        XCTAssertEqual(try! context.fetch(sessionDescriptor).count, 0, "Session should be cascade-deleted with subject")
    }
}
```

**Key Patterns:**
- **Insert related models:** Insert both the parent and related model
- **Verify relationships:** After inserting, fetch and check that the reference is correct
- **Test delete rules:** Verify cascade/orphan delete behavior works as expected

---

## Best Practices

| Do | Don't |
|----|-------|
| Use `isStoredInMemoryOnly: true` in tests | Use the real, disk-based container in tests |
| Fresh context per test (in `setUp()`) | Reuse the same context across multiple tests |
| Pass `context` to ViewModel methods | Store `context` in the ViewModel itself |
| Test ViewModel logic, then verify via fetch | Trust that the ViewModel saved correctly without checking |
| Use `#Predicate` for filtering | Fetch all data and filter in Swift (slow and error-prone) |
| Test validation separately from persistence | Combine validation and database tests in one test |
| Create seed data in the test (or setUp) | Rely on data existing from a previous test run |

---

## Common Patterns

### Pattern 1: Verify Insert
```swift
// Set up, call ViewModel method, then fetch to verify
let initialCount = try! context.fetch(FetchDescriptor<Subject>()).count
vm.addSubject(context: context)
let finalCount = try! context.fetch(FetchDescriptor<Subject>()).count
XCTAssertEqual(finalCount, initialCount + 1)
```

### Pattern 2: Verify Update
```swift
let subject = Subject(name: "Math", code: "MATH101")
context.insert(subject)
try! context.save()

subject.name = "Advanced Math"  // Modify
try! context.save()  // Persist the change

// Fetch and verify
let fetched = try! context.fetch(FetchDescriptor<Subject>()).first
XCTAssertEqual(fetched?.name, "Advanced Math")
```

### Pattern 3: Verify Delete
```swift
let subject = Subject(name: "Physics", code: "PHYS101")
context.insert(subject)
try! context.save()

context.delete(subject)
try! context.save()

let count = try! context.fetch(FetchDescriptor<Subject>()).count
XCTAssertEqual(count, 0)
```

### Pattern 4: Verify Predicate
```swift
// Insert data
let math = Subject(name: "Math", code: "MATH101")
let physics = Subject(name: "Physics", code: "PHYS101")
context.insert(math)
context.insert(physics)
try! context.save()

// Fetch with predicate
let descriptor = FetchDescriptor<Subject>(
    predicate: #Predicate { $0.name.contains("Math") }
)
let results = try! context.fetch(descriptor)
XCTAssertEqual(results.count, 1)
```

---

## Debugging Test Failures

**Test fails: "Could not find any element matching the predicate"**
- Your predicate is too strict. Print what's in the database:
  ```swift
  let allItems = try! context.fetch(FetchDescriptor<Item>())
  print("All items: \(allItems.map { $0.name })")
  ```

**Test passes, but data doesn't persist in the real app**
- You forgot to call `try! context.save()` in your ViewModel after insert/delete/update.

**Tests pass individually but fail when run together**
- Each test should have a fresh context. Check your `setUp()` method creates a new container.

**"ModelContext not configured" error**
- You forgot `.modelContainer(for: Model.self, inMemory: true)` in your preview or test.

---

## Next Steps

1. Copy `TestHelpers.swift` to your test bundle
2. Write a test for your most critical ViewModel (e.g., `StudySessionVM`)
3. Start with validation tests (no database), then add persistence tests
4. Expand predicates and relationships as you add more complex queries
