# SwiftData Guide for Study App

SwiftData is Apple's modern framework for persisting data locally on-device. Unlike UserDefaults (simple key-value) or Core Data (complex), SwiftData uses Swift's native syntax and automatic persistence.

---

## 1. Models: The Foundation

### Creating a Model

All data classes must have the `@Model` attribute and be declared as `final class`:

```swift
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var code: String
    var createdAt: Date = Date()
    
    init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}
```

### Key Rules

- **Must be `final class`** — Not a struct. SwiftData tracks changes in class instances.
- **Import SwiftData** — Required for `@Model` attribute.
- **`@Attribute(.unique)`** — Prevents duplicate IDs in the database.
- **Default values** — Provide sensible defaults for properties.

---

## 2. Setting Up the Model Container

The model container is where SwiftData stores your data. Set it up at your app's root level, typically in `StudyAppApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct StudyAppApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(
                    for: [
                        StudyFolder.self,
                        StudySession.self,
                        Subject.self,
                        User.self
                    ]
                )
        }
    }
}
```

**What this does:**
- Creates a database for all specified models
- Makes the model context available to all child views
- Handles automatic persistence (saving happens when the view updates)

---

## 3. Accessing Data in Views

### Using @Environment to Access Context

To insert, update, or delete data, you need the `modelContext`:

```swift
struct CreateSessionView: View {
    @Environment(\.modelContext) var modelContext
    @State private var sessionDuration: TimeInterval = 0
    
    var body: some View {
        VStack {
            Button("Save Session") {
                let session = StudySession(subject: nil, startedAt: Date())
                modelContext.insert(session)
                try? modelContext.save()  // Optional explicit save
            }
        }
    }
}
```

### Using @Query to Fetch Data

To read data, use `@Query`:

```swift
struct SessionsListView: View {
    @Query(sort: \StudySession.startedAt, order: .reverse)
    var sessions: [StudySession]
    
    var body: some View {
        List(sessions) { session in
            Text(session.subjectName ?? "Untitled")
        }
    }
}
```

**Common @Query patterns:**

```swift
// All sessions, newest first
@Query(sort: \StudySession.startedAt, order: .reverse) var sessions: [StudySession]

// Only completed sessions (with predicate)
@Query(
    filter: #Predicate<StudySession> { $0.endedAt != nil },
    sort: \StudySession.startedAt
) var completedSessions: [StudySession]

// Sessions from a specific subject
@Query(filter: #Predicate<StudySession> { $0.subject?.name == "Math" })
var mathSessions: [StudySession]
```

---

## 4. Understanding Relationships

A relationship connects two data models so they know about each other. Without relationships, your data is isolated; with them, it's organized hierarchically.

### Architecture for Study App

```
StudyFolder (parent)
  ├─ Subject 1 (child)
  ├─ Subject 2 (child)
  ├─ StudySession 1 (child)
  └─ StudySession 2 (child)
```

### One-to-Many Relationship (Folder → Sessions)

Most relationships in a study app are **one-to-many**: one folder has many sessions.

**Implementation:**

```swift
@Model
final class StudyFolder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    
    // Parent side: holds array of children
    @Relationship(deleteRule: .cascade, inverse: \StudySession.folder)
    var sessions: [StudySession] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class StudySession {
    @Attribute(.unique) var id: UUID = UUID()
    var subject: Subject?
    var startedAt: Date
    var endedAt: Date?
    var totalActiveDuration: TimeInterval = 0
    
    // Child side: knows its parent
    var folder: StudyFolder?
    
    init(subject: Subject? = nil, startedAt: Date = Date()) {
        self.subject = subject
        self.startedAt = startedAt
    }
}
```

### One-to-One Relationship (User → Profile)

If an entity should only have ONE related entity, use optional (not array):

```swift
@Model
final class User {
    @Attribute(.unique) var id: UUID = UUID()
    var email: String
    var createdAt: Date = Date()
    
    // Only one profile per user
    @Relationship(deleteRule: .cascade)
    var profile: UserProfile?
    
    init(email: String) {
        self.email = email
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID = UUID()
    var bio: String = ""
    var avatar: Data?
}
```

---

## 5. The @Relationship Attribute Explained

### `deleteRule` Options

| Rule | Behavior | Use Case |
|------|----------|----------|
| `.cascade` | Delete children when parent deleted | Folders with sessions — deleting folder should delete its sessions |
| `.nullify` | Keep children, remove link | Sessions linked to a user — deleting user shouldn't delete sessions |
| `.deny` | Prevent deletion if children exist | Important parent records |

**Example:**

```swift
// With .cascade
let folder = StudyFolder(name: "Math")
modelContext.delete(folder)
// ← ALL sessions in this folder are deleted too

// With .nullify
@Relationship(deleteRule: .nullify, inverse: \Subject.folder)
var subjects: [Subject] = []
modelContext.delete(folder)
// ← Subjects survive, but folder = nil
```

### `inverse` Parameter

The `inverse` parameter creates a **two-way automatic sync**:

```swift
@Model
final class StudyFolder {
    @Relationship(deleteRule: .cascade, inverse: \StudySession.folder)
    var sessions: [StudySession] = []
}

@Model
final class StudySession {
    var folder: StudyFolder?
}
```

**How it works:**

```swift
let folder = StudyFolder(name: "Math")
let session = StudySession()

// Add via array
folder.sessions.append(session)
print(session.folder)  // ✅ Automatically set to folder

// OR set the reverse
session.folder = folder
print(folder.sessions.contains(session))  // ✅ Already in array

// You only need to set ONE side; the other updates automatically
```

---

## 6. Practical Implementation for Study App

### Setting Up Your Models

**Step 1: Update Subject to be SwiftData model**

```swift
import SwiftData

@Model
final class Subject {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var code: String
    var createdAt: Date = Date()
    
    var folder: StudyFolder?  // Optional: belongs to a folder
    
    init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}
```

**Step 2: Create StudyFolder model**

```swift
import SwiftData

@Model
final class StudyFolder {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var color: String = "blue"  // for UI styling
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.folder)
    var sessions: [StudySession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Subject.folder)
    var subjects: [Subject] = []
    
    init(name: String) {
        self.name = name
    }
}
```

**Step 3: Update StudySession to link to folders**

```swift
import SwiftData

@Model
final class StudySession {
    @Attribute(.unique) var id: UUID = UUID()
    var subject: Subject?
    var subjectName: String?
    var startedAt: Date
    var endedAt: Date?
    var totalActiveDuration: TimeInterval = 0
    var totalBreakDuration: TimeInterval = 0
    var isPaused: Bool = false
    var lastResumedAt: Date
    var lastPausedAt: Date?
    var breaks: [StudyBreak] = []
    var studyScore: Int?
    var notes: String?
    
    var folder: StudyFolder?  // Link to folder
    
    init(subject: Subject? = nil, startedAt: Date = Date()) {
        self.subject = subject
        self.startedAt = startedAt
        self.lastResumedAt = startedAt
    }
}
```

### Creating Nested Data

```swift
struct CreateFolderView: View {
    @Environment(\.modelContext) var modelContext
    @State private var folderName = "Semester 1"
    
    var body: some View {
        VStack {
            TextField("Folder Name", text: $folderName)
            
            Button("Create Folder with Subjects") {
                // Create the folder
                let folder = StudyFolder(name: folderName)
                
                // Add subjects to folder
                let math = Subject(name: "Mathematics", code: "MATH101")
                folder.subjects.append(math)
                
                let physics = Subject(name: "Physics", code: "PHYS101")
                folder.subjects.append(physics)
                
                // Create a session in this folder
                let session = StudySession(subject: math)
                folder.sessions.append(session)
                
                // Insert only the parent folder
                modelContext.insert(folder)
                
                // Optional: save immediately
                try? modelContext.save()
            }
        }
    }
}
```

### Querying by Folder

```swift
struct FolderDetailView: View {
    var folder: StudyFolder
    
    var body: some View {
        List {
            Section("Subjects") {
                ForEach(folder.subjects) { subject in
                    Text(subject.name)
                }
            }
            
            Section("Study Sessions") {
                ForEach(
                    folder.sessions.sorted { $0.startedAt > $1.startedAt }
                ) { session in
                    VStack(alignment: .leading) {
                        Text(session.subject?.name ?? "Untitled")
                        Text(String(format: "%.0f min", session.totalActiveDuration / 60))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(folder.name)
    }
}
```

---

## 7. Data Flow Summary

```
┌─────────────────────────────────────────────┐
│ StudyAppApp (setup model container)         │
│ .modelContainer(for: [Models...])           │
└────────────────────┬────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
   @Query (read)          @Environment
   (automatic)            var modelContext (write)
        │                         │
   ForEach(items)         modelContext.insert()
                          modelContext.delete()
                          modelContext.save()
```

---

## 8. Common Patterns

### Organizing by Semester

```swift
// Create one folder per semester
let fall2024 = StudyFolder(name: "Fall 2024")
let spring2025 = StudyFolder(name: "Spring 2025")

// Add subjects to each semester
fall2024.subjects.append(math)
spring2025.subjects.append(advancedMath)

modelContext.insert(fall2024)
modelContext.insert(spring2025)
```

### Filtering Sessions by Folder

```swift
@Query(sort: \StudyFolder.createdAt) var folders: [StudyFolder]

var body: some View {
    List(folders) { folder in
        Section(folder.name) {
            ForEach(folder.sessions) { session in  // Direct access
                SessionRow(session: session)
            }
        }
    }
}
```

### Breaking Relationships

```swift
// Option 1: Remove from array
folder.sessions.removeAll { $0.id == session.id }
// session.folder automatically becomes nil

// Option 2: Set to nil
session.folder = nil
// automatically removed from folder.sessions array
```

---

## 9. Best Practices

✅ **DO:**
- Use descriptive folder names (e.g., "Fall 2024", "Math - Calculus")
- Set up relationships with clear parent-child hierarchy
- Use `.cascade` delete for owned relationships (folder owns sessions)
- Use `@Attribute(.unique)` for IDs
- Provide default values in initializers

❌ **DON'T:**
- Create circular relationships (A owns B, B owns A)
- Use struct as `@Model` (must be `final class`)
- Forget the `inverse` parameter (creates sync problems)
- Insert child objects separately (insert parent only)
- Use too many nested levels (keep it 2-3 deep)

---

## 10. Debugging Tips

**Check what's saved:**
```swift
@Query var allFolders: [StudyFolder]
@Query var allSessions: [StudySession]

// Add to a view temporarily to see counts
Text("Folders: \(allFolders.count), Sessions: \(allSessions.count)")
```

**Force save:**
```swift
try? modelContext.save()
```

**Delete all data (for testing):**
```swift
try? modelContext.delete(model: StudyFolder.self)
modelContext.insert(newFolder)
```





- 
