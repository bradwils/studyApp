# Feature Flags

How studyApp hides unfinished features from some builds while the same code is
promoted unchanged from `dev` to `UAT-testflight` to `master`.

Code: `studyApp/Config/` (`ReleaseRing.swift`, `FeatureFlag.swift`,
`FeatureFlags.swift`), the override screen `studyApp/Views/Dev/FeatureFlagsView.swift`,
tests in `studyAppTests/FeatureFlagsTests.swift`.

---

## TL;DR

Every build knows which **release ring** it belongs to, because CI stamps the
lane (branch or tag name) into Info.plist. Every flag declares the **widest
ring** that sees it (`enabledThrough`). A flag is on when the build's ring is
inside that limit. To roll a feature out, you change one line on `dev`
(widen `enabledThrough`) and promote as usual. You never edit a file per branch,
so promotions never conflict. Non-production builds can override any flag on
the device from Settings → Developer → Feature Flags. Production ignores
overrides.

| Ring | Lane string from CI (`StudyAppLane`) | Where builds land | Who sees it |
|---|---|---|---|
| `.local` | *absent*, for Xcode runs, previews and tests | your simulator or device | you, while developing |
| `.dev` | `dev` | TestFlight internal → **Self** | you, on your phone |
| `.uat` | `UAT-testflight` | TestFlight external → **UAT** | UAT testers |
| `.production` | `v1.2.3` tag, or anything unrecognised | TestFlight external → **Stable**, then App Store | everyone |

Rings are ordered from the smallest audience to the largest:
`.local < .dev < .uat < .production`. A flag at `.uat` is on in local, dev and
UAT builds and off in production.

---

## Why not a per-branch config file?

The obvious design is a `flags.json` (or a Swift file) whose contents differ
per branch: everything on in `dev`, a few things on in `UAT-testflight`, only
shipped things on in `master`. It doesn't work with this repo's pipeline:

- **Promotions are merge commits of the same source.** A `dev` → `UAT-testflight`
  PR carries `dev`'s actual commits ([pipeline.md](../pipeline.md#branch-rules-github-rulesets)).
  If `dev` says `groups: true` and `UAT-testflight` says `groups: false`, every
  promotion either conflicts on that file or silently overwrites UAT's value
  with dev's. Keeping them different means hand-fixing every merge, and the
  branches drift apart, which is the failure the merge-commit rule exists to
  prevent.
- **CLAUDE.md already forbids it:** "Never hardcode per-branch values in source.
  CI stamps the lane into the build."

A ring threshold avoids both problems. `FeatureFlag.swift` is **byte-identical
on every branch**. The only per-build input is the lane, which CI stamps into
the build artifact and never commits. The same line, `case .groupsTab: .dev`,
means "on in dev, off in UAT and production" whichever branch it sits on.

This works because the app has **no network backend**. There is no server
config that could differ between environments, so "the backend behaves the
same everywhere" is trivially true. Flags only gate client features: screens,
tabs, buttons and code paths in the app.

---

## How it works

### Lane → ring

`ci_scripts/ci_pre_xcodebuild.sh` writes `StudyAppLane = ${CI_TAG:-${CI_BRANCH:-unknown}}`
into `studyApp/Info.plist` before every Xcode Cloud build. `ReleaseRing.current`
reads it once at launch through `ReleaseRing(lane:)`:

| `StudyAppLane` | Ring | Why |
|---|---|---|
| absent (`nil`) | `.local` | Xcode, previews and unit tests have no CI stamp |
| `"dev"` | `.dev` | |
| `"UAT-testflight"` | `.uat` | |
| `"v1.2.3"`, `"master"` | `.production` | `master` only builds on a `v*` tag |
| anything else (`"feat/foo"`, `"unknown"`, …) | `.production` | **fails closed**: an unrecognised build sees only shipped features |

There's no explicit case for `master` or `v*`. The `default:` branch catches
them, along with any lane nobody planned for. This matters if a pull-request
test workflow is added later: it would build with a feature branch name as the
lane, and would therefore test the production configuration.

> **Swift note:** the target's default actor isolation is `MainActor`.
> `ReleaseRing` and `FeatureFlag` are declared `nonisolated enum` so these plain
> value types can be used from any context, including tests. `FeatureFlags`
> (the class) stays on the main actor, which is why the test struct is
> `@MainActor`.

### Resolution order

`FeatureFlags.isEnabled(_:)` decides in this order:

1. **Device override**, only if `allowsOverrides` (ring is not `.production`):
   `true` or `false` stored under `featureFlagOverride.<rawValue>` in `UserDefaults`.
2. **Compiled default:** `ring <= flag.enabledThrough` (exposed as `isEnabledByDefault(_:)`).

Since `.local` is the smallest ring, `.local <= anything` is always true, so
**every flag is on in Xcode builds**. That gives you the "all-on" configuration
for free while developing.

### Flow

```
Xcode Cloud: ci_pre_xcodebuild.sh
    │  LANE = CI_TAG ?? CI_BRANCH  (e.g. "UAT-testflight")
    ▼
Info.plist: StudyAppLane = "UAT-testflight"     (absent in Xcode builds)
    │
    ▼
ReleaseRing.current = ReleaseRing(lane:)  →  .uat
    │
    ▼
FeatureFlags  (@Observable, created once in StudyAppApp, injected with .environment)
    │  isEnabled(.groupsTab):
    │    1. override stored on device?  (skipped in .production)
    │    2. else  ring <= FeatureFlag.groupsTab.enabledThrough
    ▼
View: if featureFlags.isEnabled(.groupsTab) { Tab(...) }
```

`StudyAppApp` owns the single instance (`@State private var featureFlags = FeatureFlags()`)
and injects it next to `AppSession` with `.environment(featureFlags)`. Views
read it with `@Environment(FeatureFlags.self) private var featureFlags`. It's
`@Observable`, so flipping an override on the override screen updates every
view that reads it straight away.

### Fowler's vocabulary

Martin Fowler's [Feature Toggles](https://martinfowler.com/articles/feature-toggles.html)
article is the standard reference. Its terms map onto this code like this:

| Fowler term | Meaning | Here |
|---|---|---|
| **Toggle point** | "a branch point where we decide between two codepaths" | the `if featureFlags.isEnabled(...)` in a View |
| **Toggle router** | "code which is responsible for determining whether a specific Feature should be considered On or Off" | `FeatureFlags` |
| **Toggle configuration** | the inputs the router uses | `FeatureFlag.enabledThrough`, plus the CI lane and device overrides |

Fowler splits toggles into four categories: **release**, **experiment**,
**ops** and **permissioning**. This system covers **release toggles** only:
short-lived flags that hide unfinished work until it ships. Experiments (A/B
tests), ops toggles (kill switches you flip in production) and permissioning
(features for particular users) all need values that change at runtime, which
needs a remote provider (see [Limitations](#limitations--future)). Fowler
calls hardcoded configuration "perfectly suitable" for simple cases, and wants
config to flow "through our Continuous Delivery pipeline as part of the
deployment artifact". The CI-stamped lane does exactly that.

`devTools` is the one deliberate exception. It's a long-lived internal toggle
that stays at `.dev` permanently and never ships. The delete-after-shipping
rule doesn't apply to it.

Microsoft's [safe deployment practices](https://learn.microsoft.com/en-us/devops/operate/safe-deployment-practices)
and [progressive experimentation](https://learn.microsoft.com/en-us/devops/operate/progressive-experimentation-feature-flags)
treat *rings* (where code is deployed) and *flags* (who sees a feature) as two
separate controls. This design merges them: what you see is decided entirely by
which build you run.

---

## Lifecycle of a flag

Each step is a one-line change committed on `dev`. The change then reaches the
other lanes through the normal promotion ([pipeline.md](../pipeline.md)), so you
never open PRs straight into `UAT-testflight` or `master` for a flag.

Example: a new Groups tab behind `groupsTab`.

1. **Add the flag at `.local`.** Only Xcode builds see the feature. You can
   merge half-finished work to `dev` freely: the Self TestFlight build contains
   the code but the flag is off.
   ```diff
   +		case .groupsTab: .local
   ```
2. **Widen to `.dev`** when you want it on your own phone through TestFlight.
   Push to `dev`. The next Self build shows it.
   ```diff
   -		case .groupsTab: .local
   +		case .groupsTab: .dev
   ```
3. **Widen to `.uat`** when testers should see it. Commit on `dev`, then promote
   `dev` → `UAT-testflight` as usual. Mention it in TestFlight "What to Test".
   ```diff
   -		case .groupsTab: .dev
   +		case .groupsTab: .uat
   ```
4. **Widen to `.production`** when it's finished, reachable, and you've written
   its App Store Connect Review Notes (see [rules](#rules-of-the-road)). Commit
   on `dev`, promote through UAT to `master`, and tag the release.
   ```diff
   -		case .groupsTab: .uat
   +		case .groupsTab: .production
   ```
5. **Delete the flag** one release later. Remove the `case` and its three
   `switch` arms from `FeatureFlag.swift`, and replace every
   `if featureFlags.isEnabled(.groupsTab) { … }` with its body.
   ```diff
   -	case groupsTab
   ```

**Promotion ≠ exposure.** If you promote `dev` to `UAT-testflight` while
`groupsTab` is still `.dev`, the Groups code *is* in the UAT build, but the flag
evaluates to off there (`.uat <= .dev` is false). UAT testers don't see it. The
feature reaches UAT only when the widening commit does. This lets you keep
promoting `dev` on schedule while one feature stays dev-only.

---

## Examples

All of these follow the real API in `studyApp/Config/`. Flags named here
(`groupsTab`, `breakTracking`) are illustrations and don't exist yet.

### a. Adding a flag case

`FeatureFlag.swift`: add the case, then one arm in each of the three
switches. Swift's exhaustive `switch` won't compile until all three are filled
in, so you can't forget one.

```swift
nonisolated enum FeatureFlag: String, CaseIterable, Identifiable {
	case devTools
	case groupsTab

	var id: String { rawValue }

	// The widest ring that sees this flag. Roll out by widening it on dev and promoting as usual;
	// delete the case once it has shipped at .production for a release.
	var enabledThrough: ReleaseRing {
		switch self {
		case .devTools: .dev
		case .groupsTab: .local
		}
	}

	var title: String {
		switch self {
		case .devTools: "Developer Tools"
		case .groupsTab: "Groups Tab"
		}
	}

	var summary: String {
		switch self {
		case .devTools: "Debug data inspector and fake-session generator in Settings."
		case .groupsTab: "Study groups tab in the main tab bar."
		}
	}
}
```

The new flag appears on the override screen automatically (it iterates
`FeatureFlag.allCases`), and the existing ring × flag test covers it with no
test changes.

### b. Gating a tab

`GroupsView` is currently a `ContentUnavailableView` placeholder. App Review
guideline 2.1(a) rejects that kind of screen ("placeholder text, empty
websites, and other temporary content should be scrubbed before submission").
So hiding the Groups tab outside dev builds is a realistic first use.

`TabView`'s content builder supports `if`, so the toggle point wraps the `Tab`:

```swift
struct MainTabView: View {
	@Environment(AppSession.self) private var appSession
	@Environment(FeatureFlags.self) private var featureFlags

	var body: some View {
		@Bindable var session = appSession
		TabView(selection: $session.selectedTab) {
			// ...Focus, Debug, Social tabs unchanged...

			if featureFlags.isEnabled(.groupsTab) {
				Tab("Groups", systemImage: "person.3.fill", value: AppTab.groups) {
					NavigationStack {
						GroupsView()
					}
				}
			}

			// ...Sessions tab unchanged...
		}
	}
}
```

**Selected tab fallback:** `AppSession.selectedTab` starts at `.focus`, so
nothing points at a hidden tab today. If something later sets
`selectedTab = .groups` (a deep link, restored state), check the flag first
and fall back to `.focus`. Otherwise the `TabView` is bound to a tab that
doesn't exist.

### c. Gating a Section or toolbar item

The real wiring is in `studyApp/Views/Settings/SettingsView.swift`. `Form`
and `.toolbar` builders both accept `if`:

```swift
@Environment(FeatureFlags.self) private var featureFlags

// in the Form
if featureFlags.isEnabled(.devTools) {
	Section("Debug") {
		Button {
			insertFakeSession()
		} label: {
			Label("Generate Fake Study Session", systemImage: "wand.and.stars")
		}
	}
}

// in .toolbar
if featureFlags.isEnabled(.devTools) {
	ToolbarItem(placement: .topBarTrailing) {
		NavigationLink {
			DebugDataView()
		} label: {
			Image(systemName: "ladybug")
		}
	}
}
```

The "Developer" section that links to the override screen is gated on
`featureFlags.allowsOverrides` instead of on a flag, and marked `// DEV ONLY`.

### d. ViewModel logic: pass the decision in

ViewModels never read `FeatureFlags`. The View, which is the toggle point, asks
the flag and passes the answer into the VM method. Say you wanted to gate break
tracking in `StudyTrackingViewModel`. Its real start method is
`startSession(ctx:)`, and you would add a parameter:

```swift
// View, e.g. TrackingPageContent
@Environment(FeatureFlags.self) private var featureFlags

vm.startSession(ctx: modelContext, tracksBreaks: featureFlags.isEnabled(.breakTracking))
```

```swift
// StudyTrackingViewModel
func startSession(ctx: ModelContext, tracksBreaks: Bool) {
	// ...
}
```

Why:

- **CLAUDE.md layer rules.** VMs don't import SwiftUI and don't own environment
  values. `@Environment` only works inside a View.
- **Toggle point at the edge.** Fowler recommends putting product toggles at
  the edge (the UI) and keeping the toggle point separate from the router. The
  VM's logic just takes a `Bool`. It doesn't know flags exist.
- **Testable.** A VM test calls `startSession(ctx:tracksBreaks:)` with `true`
  and with `false`. It doesn't need to build `FeatureFlags` or `UserDefaults`.
- **Easy removal.** When the flag is deleted, you remove one argument at one
  call site and the dead branch in the VM.

The CLAUDE.md rule "methods do not take parameters the VM already owns" doesn't
apply here: the flag decision belongs to the View layer, not the VM.

### e. Previews

Any view that reads `@Environment(FeatureFlags.self)`, directly or through a
child, **crashes in its preview** unless an instance is injected:

```swift
#Preview {
	SettingsView(settingsSheetDetent: .fraction(0.5))
		.environment(FeatureFlags())
}
```

`FeatureFlags()` uses `ReleaseRing.current`. Previews have no CI stamp, so
that's `.local`, with every flag on. To preview what the App Store build looks
like:

```swift
#Preview("Shipped") {
	SettingsView(settingsSheetDetent: .fraction(0.5))
		.environment(FeatureFlags(ring: .production, defaults: UserDefaults(suiteName: "preview")!))
}
```

Passing a separate `UserDefaults` suite keeps preview overrides out of the
simulator's real defaults. `FeatureFlagsView`'s own preview does the same with
`ring: .dev`.

### f. Tests

Build `FeatureFlags(ring:defaults:)` directly with a fresh, uniquely named
defaults suite so tests never share stored overrides:

```swift
import Foundation
import Testing
@testable import studyApp

@MainActor
struct GroupsTabTests {

	private func freshDefaults() -> UserDefaults {
		UserDefaults(suiteName: UUID().uuidString)!
	}

	@Test("Every flag is on in local builds")
	func localIsAllOn() {
		let flags = FeatureFlags(ring: .local, defaults: freshDefaults())
		#expect(FeatureFlag.allCases.allSatisfy { flags.isEnabled($0) })
	}

	@Test("A dev override can force the Groups tab off")
	func overrideHidesGroupsTab() {
		let flags = FeatureFlags(ring: .dev, defaults: freshDefaults())
		flags.setOverride(false, for: .groupsTab)
		#expect(!flags.isEnabled(.groupsTab))
	}
}
```

`FeatureFlagsTests.defaultResolution` already checks every ring × every flag
against `ring <= flag.enabledThrough`. **Widening or adding a flag never
requires editing tests.** Don't write tests that hardcode a specific flag's
ring, such as "groupsTab is off in production". They break on every widening.
Test the feature's behaviour with the flag on and off instead (for a VM, pass
`true` and `false`).

### g. The override screen

On **local, dev and UAT** builds: Settings (currently the **Debug** tab) →
**Developer** → **Feature Flags**.

- The header shows the build's ring. The Settings footer shows the raw lane.
- Each flag has a menu: **Default (On/Off)**, **On**, **Off**. An orange dot
  marks overridden flags.
- **Reset All** clears every override.
- Overrides take effect immediately and persist on the device in `UserDefaults`.

The Developer section is gated on `allowsOverrides` rather than on `devTools`,
so UAT testers can reach it too. For example, they could turn `devTools` on.

In **production** the section is hidden, and `FeatureFlags` also ignores any
override already stored: `init` doesn't load them, `isEnabled` skips them and
`setOverride` does nothing. Why the extra guard? TestFlight and App Store
builds share a bundle identifier. Apple doesn't document whether an App Store
install over a TestFlight build keeps its `UserDefaults`, so a tester's old
"force on" might survive. Production ignoring overrides rules that out.

---

## Rules of the road

1. **Delete a flag one release after it reaches `.production`. Keep about 5 or
   fewer live flags.** Toggles are "inventory which comes with a Carrying Cost".
   Fowler suggests removal tasks, expiration dates and "a limit on the number of
   toggles". ([Fowler](https://martinfowler.com/articles/feature-toggles.html))
2. **Never reuse or rename a flag.** The `rawValue` is the `UserDefaults`
   override key, so a reused name inherits stale overrides and stale meaning. In
   2012 Knight Capital repurposed an old "Power Peg" flag while dead code was
   still deployed on 1 of 8 servers. In about 45 minutes it made roughly 4
   million executions and lost more than $460M.
   ([SEC order](https://www.sec.gov/files/litigation/admin/2013/34-70694.pdf))
3. **Toggle points only in Views.** ViewModels and Models never read
   `FeatureFlags`; pass the decision in ([example d](#d-viewmodel-logic-pass-the-decision-in)).
   Product toggles belong "at the edge", separate from the router.
   ([Fowler](https://martinfowler.com/articles/feature-toggles.html))
4. **Widen to `.production` only when the feature is finished, reachable, and
   described in App Store Connect Review Notes.** Guideline 2.3.1(a): "All new
   features, functionality, and product changes must be described with
   specificity in the Notes for Review section of App Store Connect (generic
   descriptions will be rejected) and accessible for review."
   ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))
5. **Code behind a disabled flag must do nothing, and no placeholder UI may
   reach production.** Guideline 2.1(a): "...placeholder text, empty websites,
   and other temporary content should be scrubbed before submission...".
   Guideline 2.5.19 (the hidden/dormant rule, formerly numbered 2.3.1): "Don't
   include any hidden, dormant, or undocumented features in your app; your
   app's functionality should be clear to end users and App Review. Attempting
   to hide undocumented features in your app binary, such as through code
   obfuscation or other methods, is grounds for removal...". Unfinished code
   that ships disabled is a grey zone. Keep it unreachable: no background work,
   no network calls, no stored data. Ship it disabled only as long as you have to.
   ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/))
6. **Test the next release's configuration, and test with everything on.** "We
   must perform validation on our artifact both with the toggle flipped On and
   flipped Off." Before promoting to `master`, check the UAT build, which runs
   the configuration that's about to ship. Xcode builds (`.local`) are all-on.
   ([Fowler](https://martinfowler.com/articles/feature-toggles.html))

---

## Limitations & future

**No production kill switch.** A flag's value is compiled into the reviewed
binary, so you can't turn a broken feature off in the App Store without a new
build. Mitigations:
- [Pause a phased release](https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases/)
  to stop the update spreading to more automatic-update users.
- Narrow the flag back to `.uat` in a `hotfix/*` branch ([pipeline.md](../pipeline.md#hotfixes))
  and [request an expedited review](https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review/).

**No per-tester targeting.** Ring == lane, so everyone on the same build sees
the same thing. You can't show a feature to half the UAT group. Device
overrides are the only exception.

**Every exposure change ships in a reviewed binary.** This is a plus with App
Review: the app can't change behaviour after review. The cost is that each
exposure change needs a new build.

### When to add a remote provider

Add one when you need a real kill switch, gradual percentage rollouts or
experiments. The design is ready for it as long as **`isEnabled(_:)` stays the
only API call sites use**. A provider plugs into `FeatureFlags` as a new step
between the device override and the compiled default. The compiled
`ring <= enabledThrough` value becomes the provider's in-app default, used
offline and before the first fetch. No View changes.

Recommended first: **Firebase Remote Config**. It's free, takes defaults
in-app, caches values and supports real-time updates. The vendor-neutral
**OpenFeature** API is the right shape (its no-op provider returns the default
and evaluation "MUST NOT throw"), but the Swift SDK is still alpha (v0.7.0).

App Review risk: 2.5.2 says apps may not "download, install, or execute code
which introduces or changes features or functionality". Flipping a remote
boolean isn't downloading code, but rejections tend to come when remote config
changes behaviour after review. Remote-controlled features still need to be
described in Review Notes and reachable during review (2.3.1(a), 2.5.19).

| Option | Cost / hosting | Notes |
|---|---|---|
| [Firebase Remote Config](https://firebase.google.com/docs/remote-config/ios/get-started) | free (Spark plan), hosted | in-app defaults, cached, 12h default minimum fetch interval, real-time updates; usable as a kill switch |
| [LaunchDarkly](https://launchdarkly.com/docs/sdk/features/offline-mode) | free developer plan, hosted | on-device cache |
| [Unleash](https://docs.getunleash.io/feature-flag-tutorials/ios) | open source | needs a server you run |
| [ConfigCat](https://configcat.com/docs/sdk-reference/ios/) | hosted | 60s polling, `UserDefaults` cache |
| [Statsig](https://docs.statsig.com/client/iosClientSDK) | free tier, hosted | acquired by OpenAI (Sep 2025), so the roadmap is uncertain |
| [OpenFeature Swift SDK](https://github.com/open-feature/swift-sdk) | vendor-neutral API | alpha (v0.7.0); [spec](https://github.com/open-feature/spec/blob/main/specification/sections/01-flag-evaluation.md) |

---

## Playbook for agents

Task briefs an orchestrator can hand to an agent as-is. Replace `<flagName>`
and `<ring>`. All work happens on a branch off `dev` (or directly on `dev`),
following CLAUDE.md's commit conventions.

### Add a flag

```
Add a release flag `<flagName>` gating <feature>.
1. In studyApp/Config/FeatureFlag.swift add `case <flagName>` and an arm in all three
   switches: enabledThrough -> .local, title -> short name, summary -> one sentence.
2. At each toggle point (Views only) read
   `@Environment(FeatureFlags.self) private var featureFlags` and wrap the UI in
   `if featureFlags.isEnabled(.<flagName>) { ... }`. If a ViewModel needs the decision,
   add a Bool parameter and pass `featureFlags.isEnabled(.<flagName>)` from the View.
3. Every #Preview of a view that (directly or via children) reads FeatureFlags must have
   `.environment(FeatureFlags())`.
4. Do not edit studyAppTests/FeatureFlagsTests.swift.
Commit: feat(flags): add <flagName> flag [<Agent>]
Verify: xcodebuild build -project studyApp.xcodeproj -scheme studyApp -destination generic/platform=iOS
        and xcodebuild test -project studyApp.xcodeproj -scheme studyApp both pass;
        grep -rn "FeatureFlags" studyApp/ViewModels studyApp/Models prints nothing.
```

### Widen a flag

```
Widen `<flagName>` to `<ring>` (one of .dev, .uat, .production).
1. On dev, change only `case .<flagName>: <old>` to `case .<flagName>: <ring>` in
   studyApp/Config/FeatureFlag.swift. Widen one step at a time.
2. If <ring> is .production: confirm the feature is finished, reachable from normal UI,
   has no placeholder content, and draft the App Store Connect "Notes for Review" text
   describing it specifically. Include that draft in your report.
3. Do not open PRs into UAT-testflight or master; the change rides the normal promotion
   (pipeline.md).
Commit: feat(flags): widen <flagName> to <ring> [<Agent>]
Verify: git diff shows exactly one changed line; xcodebuild test passes with no test edits.
```

### Remove a shipped flag

```
Remove `<flagName>`, which has been at .production for at least one release.
1. grep -rn "\.<flagName>\b" studyApp studyAppTests to find every use.
2. At each `if featureFlags.isEnabled(.<flagName>) { A }` keep A and drop the `if`.
   With an `else { B }`, keep A and delete B plus anything only B used.
   For a VM Bool parameter fed by the flag, remove the parameter and its false branch.
3. Remove `@Environment(FeatureFlags.self)` from views that no longer read it.
4. Delete `case <flagName>` and its three switch arms from FeatureFlag.swift.
   Never reuse the name later.
5. Tests need no change, except: the override tests in FeatureFlagsTests.swift use
   `.devTools` as a fixture. If the flag being removed is devTools, point them at
   another case.
Commit: refactor(flags): remove shipped <flagName> flag [<Agent>]
Verify: grep -rn "\.<flagName>\b" studyApp studyAppTests prints nothing;
        xcodebuild build and xcodebuild test pass.
```

### Audit flag debt

```
Report which flags should be removed.
1. List flags at production:
   grep -nE 'case \.[A-Za-z]+: \.production$' studyApp/Config/FeatureFlag.swift
2. For each, find the commit that widened it and whether a release contains it:
   git log -1 --format='%h %cs' -S 'case .<flagName>: .production' -- studyApp/Config/FeatureFlag.swift
   git tag --list 'v*' --contains <sha>
   If any v* tag contains it, the flag has shipped: schedule removal now (it lands in the
   next release).
3. Count all cases in FeatureFlag; flag it if more than ~5 are live (devTools excluded).
Make no code changes.
Verify: report lists every case from FeatureFlag.allCases with its ring, the first v* tag
        containing its .production widening (or "not shipped"), and a remove/keep verdict.
```

---

## References

- Martin Fowler / Pete Hodgson, *Feature Toggles*: https://martinfowler.com/articles/feature-toggles.html
- Microsoft, safe deployment practices: https://learn.microsoft.com/en-us/devops/operate/safe-deployment-practices
- Microsoft, progressive experimentation with feature flags: https://learn.microsoft.com/en-us/devops/operate/progressive-experimentation-feature-flags
- OpenFeature flag evaluation spec: https://github.com/open-feature/spec/blob/main/specification/sections/01-flag-evaluation.md
- OpenFeature Swift SDK: https://github.com/open-feature/swift-sdk
- Firebase Remote Config (iOS): https://firebase.google.com/docs/remote-config/ios/get-started
- LaunchDarkly offline mode: https://launchdarkly.com/docs/sdk/features/offline-mode
- Unleash iOS tutorial: https://docs.getunleash.io/feature-flag-tutorials/ios
- ConfigCat iOS SDK: https://configcat.com/docs/sdk-reference/ios/
- Statsig iOS client SDK: https://docs.statsig.com/client/iosClientSDK
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple, release a version update in phases: https://developer.apple.com/help/app-store-connect/update-your-app/release-a-version-update-in-phases/
- Apple, request expedited review: https://developer.apple.com/help/app-review/after-submitting-for-review/request-expedited-review/
- SEC order, Knight Capital (2013): https://www.sec.gov/files/litigation/admin/2013/34-70694.pdf
