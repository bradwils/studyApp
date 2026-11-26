---
name: blast-radius
description: "Find what a Swift/SwiftUI change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of with a real test or script instead of a writeup. Use for 'blast radius of X', 'what could this break', or reviewing a small iOS diff you don't trust."
disable-model-invocation: true
---

# Blast radius (Swift / SwiftUI / iOS)

Find what a change breaks somewhere else, before it ships. Use for "blast radius of X", "what could this break", or reviewing a small diff you don't trust yet.

Companion to `how` and `why`. `how` tells you what the code does. `why` tells you why it's shaped that way. Blast radius tells you what it breaks somewhere else.

Listing the callers is not the job. Grep does that in a second. The job is the breakage grep won't show you, and in an iOS app most of it hides in data on disk, in the SwiftUI update model, and in lifecycle timing.

## Don't trust your own writeup

A blast-radius writeup that sounds right is worthless. It reads as convincing whether or not it's true. So don't hand back the writeup. Find the one or two facts the whole thing depends on and prove them by running code.

### How sure are you

For each fact the change's safety depends on, get it as far down this list as is cheap, and say where it stopped.

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or Apple's documented behavior for the exact API and OS version.
3. You showed the bad case can't happen. You walked the failure step by step and it doesn't reach.
4. You ran it. A test or script that calls the real code and fails loud if you're wrong.
5. You reproduced it in the running app (simulator or device), including a relaunch or an upgrade over an old install when the risk is persistence.

Step 4 is usually one small Swift Testing or XCTest case that uses the real model types with an isolated in-memory `ModelContainer` and an injected clock, like the existing ones in `studyAppTests/`. For pure logic with no SwiftData or UIKit, a standalone `swift script.swift` run is cheaper.

**Build rule.** Running the proof test is a gate, so the build rule in AGENTS.md allows it. Run it once, focused on the one suite:

```bash
xcodebuildmcp simulator test --project-path studyApp.xcodeproj --scheme studyApp --simulator-name "iPhone 17" --use-latest-os --extra-args "-only-testing:studyAppTests/<Suite>" --style minimal
```

If the user has said not to build in this session, write the test, show the command, and mark the fact "proven by test, not run", which is step 3 at best. For step 5, use the **simslim** skill.

## Steps

1. Read the change. The diff, the symbols it adds, changes, renames, and deletes, and what it now does differently, including the part the diff doesn't spell out. Pull the PR and its commits. Check which files it touches by layer (Model, ViewModel, View, App) and whether the AGENTS.md layer rules still hold.
2. Find the one fact it's safe because of. Most changes that look risky are safe because of a single fact, like "this property has a default so SwiftData's lightweight migration handles it" or "this view is only ever created once at the root". Find that fact. If it holds, most risky cases are cleared at once. Spend your time here, not on a long list of maybes.
3. Look where grep stops. Walk the checklist below for every layer the diff touches.
4. Be honest about each risk. Give it a real chance of happening and a real cost if it does. Keep the risks you confirmed. List the ones you checked and cleared separately. Cite a real `file:line`, a search that finds nothing is still an answer, and never make up a caller or an API.
5. Prove the one fact. Write the test or script, run it if allowed, and paste what happened. If not run, say so.

## Where Swift/iOS breakage hides

Check only the rows the diff touches.

**SwiftData and persistence (highest cost: user data loss or launch crash)**
- Model property added, removed, renamed, retyped, or made optional/non-optional. Does an existing store open? Lightweight migration needs a default or optional. A rename needs `@Attribute(originalName:)`. Check for a `VersionedSchema` / migration plan; if none exists yet, say a reinstall is needed (per AGENTS.md) rather than calling it safe.
- Model added or removed in `.modelContainer(for:)` in `StudyAppApp.swift`, in previews, and in test containers. A model missing from a container crashes at first use, not at compile time.
- `@Relationship` delete rule or `inverse` changed. Which deletes now cascade or nullify? Session deletion in particular: check the active-session exclusion still holds.
- `@Attribute(.unique)` added or changed: upsert behavior and existing duplicates.
- Enums or `Codable` structs stored in a model: changing a case or raw value breaks decoding of rows already on disk.
- `#Predicate` / `@Query` edits: predicates compile but can fail at runtime on unsupported expressions. Sort and filter changes alter what every screen using that query shows.
- Insert, delete, or context changes without an explicit `save()`. Which `ModelContext` is it, and is it the one the UI reads?
- Data also lives outside SwiftData: `UserDefaults`/`@AppStorage` keys, files, Keychain, JSON from the old Stores migration, CloudKit if enabled. A renamed key silently resets a setting.

**SwiftUI update and identity model (breaks quietly, shows up as jank or lost state)**
- `@State`, `@StateObject`/`@State` with `@Observable`, `@Bindable`, `@Environment`: where is the object created? A view model built in a view body or initializer is recreated on parent re-render and loses state. Check who owns `StudyTrackingViewModel` and that it stays single.
- `@Observable` invalidation: a view re-renders when a property it reads changes. A newly read property, or a computed property that reads many, widens re-renders. Timer ticks at 1 Hz propagating into large view trees are the usual cost in this app.
- View identity: `ForEach` ids, `.id()` changes, `if/else` branches that swap view type, and `.task(id:)` all reset state and animations. Unstable ids (indices, `UUID()` in the body) reorder or restart rows.
- `.task`, `.onAppear`, `.onChange`, `.onDisappear`: run counts and ordering change when identity or navigation structure changes. Check for work that now runs twice or never.
- Environment and preference keys: removing a value a descendant still reads falls back to its default with no warning.
- Navigation: changes to `NavigationStack` paths, `TabView` selection, sheets, and `fullScreenCover` alter back behavior and state restoration. Check `MainTabView` and the app navigation tests.
- Previews: a signature or init change breaks every `#Preview` that builds it, and previews needing a container crash at render time.

**Concurrency and lifecycle**
- `@MainActor` isolation added, removed, or inferred. Swift 6 mode and strict-concurrency settings turn warnings into errors. A `Task` created in a view or VM outlives it unless cancelled.
- `ModelContext` and `@Model` instances are not `Sendable`. Passing them across actors or into a detached task is a latent crash.
- Timer, clock, and date logic: backgrounding, device sleep, time zone or DST change, clock changes, and relaunch mid-session. Anything that derives elapsed time from a running counter rather than stored timestamps drifts or resets.
- Scene phase transitions, notifications, Live Activities, background tasks, and app termination while a session is active.
- Process death: what state was only in memory and is lost on relaunch?

**Platform, OS and build**
- API availability. A new API needs `#available` or a deployment-target check; check the target in the project settings, not memory. Anything new in iOS 26/27 SDKs compiled on a newer Xcode than CI uses will fail on Xcode Cloud.
- Compile-time breakage across targets: app, widget or other extensions, tests, UI tests. A symbol made `private`, moved, or deleted can break a target grep in the app folder won't cover. Check `project.pbxproj` membership when files are added or moved, and `Info.plist` / entitlements / capability changes.
- Accessibility: Dynamic Type, VoiceOver labels, and contrast regress when a fixed font, `.accessibilityHidden`, or a custom control replaces a standard one. Layout at the largest text size and on small devices (SE) and iPad size classes.
- Localization: new user-facing strings not in the String Catalog, or keys changed.
- Dark mode, reduced motion, and right-to-left layouts when colors or animations are hard-coded.

**Release pipeline**
- Changes to `ci_scripts/`, `Info.plist` stamps, `MARKETING_VERSION`, or build number offset affect Xcode Cloud builds and TestFlight notes on every lane.
- Docs that must change with the code: `AGENTS.md` (CLAUDE.md only imports it), `pipeline.md` and the workflow docs.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which step you got it to, and show the proof. If you couldn't prove it, write unproven.
- **Risks.** Each names how it breaks, the `file:line`, how likely and how bad (data loss and launch crash rank above visual glitch), and how to check. Paste the proof for the ones that matter. Say whether it needs a reinstall or a migration.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug, including the test or script you wrote and the exact command to run it. For persistence risks, include the upgrade check: install the previous build, create data, install this build over it, relaunch.

Write it through `unslop`, cite real code, and strip anything private before it goes anywhere public.

**Reply:** the writeup above, with the one safety fact either proven or marked unproven. Mention in one line that no build was run, if none was.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
