# Architecture and SwiftUI quality audit

Source baseline: `e191db5` (`chore/verification-protocols`, parent PR #229), reviewed 23 November 2026. This is an actionable source review, not a build or device certification. Independent SwiftUI and persistence reviews were reconciled against the source below; no Xcode build, simulator run or device inspection was performed.

## Scope and inventory

The repository has 124 app Swift files: 89 views (52 under `Views/Dev`), 15 view models, 14 model files, three app files, two extensions and one shared component. There are 11 unit-test/support Swift files. Reachability matters more than file count:

| Area | Current boundary | Audit treatment |
| --- | --- | --- |
| [App composition](../studyApp/App/StudyAppApp.swift#L10), [tabs](../studyApp/App/MainTabView.swift#L19) | One root tracking owner and model container; Focus, Debug/Settings, Social, Groups and Sessions tabs | Review the release-reachable flows, including prototypes composed into them |
| [Focus](../studyApp/Views/Focus/FocusSessionScreen.swift#L13) | Real tracking state, shared pager scaffold, local timeline rendering | Primary SwiftUI/state/accessibility surface |
| [Settings](../studyApp/Views/Settings/SettingsView.swift#L41), [Sessions](../studyApp/Views/Sessions/SessionsView.swift#L13) | Real subject editing and persisted history | Primary mutation, reporting and data-loss surfaces |
| [Social](../studyApp/Views/Social/SocialFeedView.swift#L9), [profile](../studyApp/Views/Profile/StudyMemberDetailView.swift#L14), [Groups](../studyApp/Views/Groups/GroupsView.swift#L5) | Social/profile use samples; Groups shows an unavailable state | A sample composed into a real tab needs an explicit product boundary; an honest unavailable state is acceptable |
| [Design Lab](../studyApp/Views/Dev/DesignLab/FocusLabHost.swift#L9), StudyItem/tag/field inspectors | Settings links into debug tools only under `#if DEBUG`; lab owns a separate mock session | Intentional experiments, not evidence that production uses mock persistence |

`FocusIntensitySlider`, `CustomBottomSheet`, `ModesView` and `UserProfile` have no current production callers found by reference search. Their experiments/registration choices are not release defects. Session restoration and versioned migrations need product/release contracts: the repository explicitly allows deleting abandoned unfinished sessions and defers migration until UAT. Neither is classified here as an accidental implementation failure.

## Fix source patterns first

Priority reflects user impact and the likelihood an agent will copy the pattern. P1 protects saved work; P2 corrects displayed facts, state ownership and accessibility. These findings describe the baseline, not fixes already delivered by this document.

### 1. P1 — Bulk history deletion has no recovery boundary

**Confirmed source behavior:** [SessionsView toolbar](../studyApp/Views/Sessions/SessionsView.swift#L35) immediately calls `removeAllSessions` on one tap. [SessionViewerViewModel](../studyApp/ViewModels/SessionViewerViewModel.swift#L23) deletes every eligible record and saves; there is no confirmation or undo. The currently owned ID is correctly protected, but all other history can be lost accidentally.

**Fix at the source:** Make the production bulk action present a count-aware confirmation (or a working undo). Keep active-ID protection in the command as well as the view; the existing cascade deletion implementation is deliberate. [DebugModelListView](../studyApp/Views/Dev/DebugModelListView.swift#L52) already demonstrates a confirmation boundary.

**Acceptance/prevention:** Opening or cancelling the prompt changes no data; confirming deletes only eligible graphs and preserves the active graph. Reuse the existing [ownership/cascade checks](../studyAppTests/SwiftDataIntegrityTests.swift#L309); review any new destructive bulk affordance for the same recovery boundary.

### 2. P1 — Data editors report apparent success when saving fails

**Confirmed source behavior:** [SubjectsEditorVM.addSubject](../studyApp/ViewModels/Settings/SubjectsEditorVM.swift#L17) discards a save error and clears the draft anyway; `removeSubject` also suppresses save errors. [SessionViewerViewModel.removeAllSessions/deleteSessions](../studyApp/ViewModels/SessionViewerViewModel.swift#L31) turns fetch failure into an empty result and discards save failure. A failed write may remain only in the shared context while the interface appears finished. This is especially harmful as the template for future editors.

**Fix at the source:** Return or expose operation failure to the owning screen, preserve the draft/pending operation, and provide an explicit retry. Retry an already-inserted pending subject rather than inserting a duplicate. Do not indiscriminately roll back the root context, which may also hold a live session. Copy the explicit error boundary in [StudyTrackingViewModel.save](../studyApp/ViewModels/StudyTrackingViewModel.swift#L204) and [FocusSessionScreen's alert](../studyApp/Views/Focus/FocusSessionScreen.swift#L20), then make the retry behavior concrete rather than assuming autosave is proof of success.

**Acceptance/prevention:** An induced fetch/save failure remains visible and recoverable; retry creates one subject or completes the intended deletion. Successful writes refetch through a fresh context with autosave disabled. Update the `try? save()` guidance in [AGENTS.md](../AGENTS.md#L179) and its [CLAUDE.md counterpart](../CLAUDE.md) with the chosen error contract when the implementation lands. A blanket ban on `try?` would not distinguish deliberate best-effort work from these user-data operations.

### 3. P2 — Session detail counts breaks as active study until completion

**Confirmed source defect:** [StudySession.totalActiveDuration](../studyApp/Models/StudySession.swift#L113) returns all wall time whenever `endedAt == nil`; [SessionDetailView](../studyApp/Views/Sessions/SessionDetailView.swift#L15) labels that value “Active duration.” Study for 60 seconds and pause for 120: detail approaches 180 seconds active, while [SessionTiming.activeElapsed](../studyApp/ViewModels/Focus/SessionTiming.swift#L45) correctly remains 60. Resumed unfinished sessions also include earlier breaks.

**Fix at the source:** Define a date-explicit persisted-session summary that excludes closed and open breaks and use it in history/detail reporting. Share the duration contract with the live timing owner; do not fix only the displayed label or add a second independent timer. Define the cutoff/status for abandoned unfinished records separately.

**Acceptance/prevention:** With the same supplied dates, running, paused, resumed and completed summaries agree with tracking elapsed time. Add this missing unfinished-session case beside [completed persistence assertions](../studyAppTests/SwiftDataIntegrityTests.swift#L166). Live refresh of unfinished rows/details is a separate device check: those views currently have no timeline and depend on incidental invalidation.

### 4. P2 — Deleting the final subject bypasses selection repair

**Confirmed ownership gap:** [ActiveSubjectList.repairSelection](../studyApp/Views/Components/ActiveSubjectList.swift#L24) can clear a stale selection, but all its lifecycle/change handlers are attached only to the nonempty `Picker` branch at line 48. When deleting the final subject switches to the empty `Text`, that branch no longer repairs the tracking owner's reference. [startSession](../studyApp/ViewModels/StudyTrackingViewModel.swift#L107) then reads `selectedSubject` to construct a relationship and name.

**Fix at the source:** Attach repair to the enclosing stable boundary so it also runs for an empty query and when selection becomes enabled. Keep the existing rule that selection cannot change during an active session. This is a small representative source correction; it does not require replacing observable models with a store framework.

**Acceptance/prevention:** Select the only subject, delete it in Settings, return to Focus and start a subjectless session; selection must be nil and the new record must not reference a deleted subject. Repeat with another remaining subject, then with a newly added subject. The missing repair path is confirmed; a SwiftData crash or reinsertion consequence is **not** established without runtime evidence.

### 5. P2 — Real tabs present prototype values as user facts

**Confirmed source behavior:** [TrackingPageContent](../studyApp/Views/Focus/Pages/TrackingPageContent.swift#L71) shows `"temp"` during a real session, its header always shows total `"00:00:00"` at line 127, and online-friend count stays zero. It always composes [mock media/leaderboard content](../studyApp/Views/Components/HorizontalContentScrollRow.swift#L35). [MainTabView](../studyApp/App/MainTabView.swift#L32) also constructs Social with the [sample-default VM](../studyApp/ViewModels/SocialFeedViewModel.swift#L22): fictional activity, Math, streak 5 and daily time 02:34. Every [member profile](../studyApp/Views/Profile/StudyMemberDetailView.swift#L14) reports the same activity. These paths are outside the intentional lab.

**Fix at the source:** Make real composition choose real local facts or an explicit unavailable state; keep samples in previews/lab/demo composition. Remove unfinished secondary widgets until they have a truthful contract. Derive local totals from persisted sessions using the duration contract above. This does not require adding networking now or banning `ObservableObject`.

**Acceptance/prevention:** A normal release launch contains no invented activity or `"temp"`; completing local study changes any displayed local total. Preview/demo data must require an explicit opt-in at composition, so copying a screen cannot silently ship its fixture.

### 6. P2 — Decorative production motion ignores Reduce Motion

**Confirmed source policy gap:** [TimerGradientBackground](../studyApp/Views/Components/TimerGradientBackground.swift#L58) starts indefinite animations unconditionally, including [repeat-forever modifiers](../studyApp/Views/Components/TimerGradientBackground.swift#L95) and [queued animation mutations](../studyApp/Views/Components/TimerGradientBackground.swift#L135). [FocusBackgroundLayer](../studyApp/Views/Focus/Components/FocusBackgroundLayer.swift#L36) uses it in the real Focus screen. That parent reads Reduce Motion only for page blend weights; the animation owner never reads it.

**Fix at the source:** Give the background a static Reduce Motion treatment and update/cancel decorative animation when the preference changes. Keep animation policy at its owner, as [SessionControls.withMorphAnimation](../studyApp/Views/Focus/Components/SessionControls.swift#L73) already does. Do not infer a measured battery or frame-rate problem from source alone.

**Acceptance/prevention:** Check idle, running and paused Focus with Reduce Motion on, then toggle it while visible. Decorative movement must stop; progress remains understandable. New reusable animated components should define the same preference behavior before lab promotion.

### 7. P2 — Collapsing the focus picker does not define semantic visibility

**Confirmed source gap; device manifestation pending:** [FocusTargetControls](../studyApp/Views/Focus/Components/FocusTargetControls.swift#L14) keeps the Hours/Minutes wheels mounted and only collapses/clips their frame when a target exists. It has no accessibility-hidden or disabled policy. Visual clipping alone is not an explicit accessibility contract; whether these invisible wheels remain traversable must be checked with VoiceOver.

**Fix at the source:** Hide the collapsed picker from accessibility and disable hidden interaction while preserving the intended visual transition, or remove it from the hierarchy if the transition no longer needs retention.

**Acceptance/prevention:** VoiceOver cannot navigate to or adjust Hours/Minutes during a target; resetting restores both controls. Review retained, visually hidden controls for semantic visibility rather than applying a blanket rule against frame animations.

## Device validation needed before claiming rendering defects

| Hypothesis | Source reason to inspect | Focused acceptance |
| --- | --- | --- |
| Short-height / large-type overflow | [FocusPageScaffold](../studyApp/Views/Focus/FocusPageScaffold.swift#L28) reserves header/timer slots; tracking adds controls and a [scaled 200-point row](../studyApp/Views/Components/HorizontalContentScrollRow.swift#L6) without vertical scrolling | Smallest supported phone, landscape, and accessibility type sizes keep Start/Pause/Finish, subject selection and focus controls reachable. If not, adapt/scroll content while retaining one shared timer-slot contract |
| Timer spoken value omitted | [SessionTimerText](../studyApp/Views/Components/SessionTimerText.swift#L31) supplies a generic accessibility label without an explicit duration value | VoiceOver speaks the current elapsed/break/remaining duration. If the label masks digits, set label and value from the same timeline tick |
| Unfinished detail timing/status diverges | [SessionDetailView](../studyApp/Views/Sessions/SessionDetailView.swift#L12) says “In progress” for every unfinished record; [SessionsView](../studyApp/Views/Sessions/SessionsView.swift#L50) distinguishes owned from abandoned records | Choose a consistent abandoned-record status/cutoff; verify visible live values refresh without a navigation round trip |

## Good source patterns to copy

| Pattern | Concrete example and limit |
| --- | --- |
| Stable state ownership | [StudyAppApp](../studyApp/App/StudyAppApp.swift#L10) owns tracking/session once and provides the root model container; feature screens receive tracking explicitly |
| Focused observation and stable identity | [FocusPager](../studyApp/Views/Focus/FocusPager.swift#L24) uses enum page identity; [FocusPagerLayer](../studyApp/Views/Focus/Pager/FocusPagerScaffold.swift#L94) scopes per-frame reads. Preserve these boundaries; no evidence here supports replacing the pager wholesale |
| Local clock rendering | [TimerDisplay](../studyApp/ViewModels/Focus/TimerDisplay.swift#L11) captures value snapshots; [SessionTimerText](../studyApp/Views/Components/SessionTimerText.swift#L49) owns timeline ticks; [SessionTiming](../studyApp/ViewModels/Focus/SessionTiming.swift#L32) takes explicit dates. Do not add a globally ticking observable property |
| Persistence ownership | [Subject](../studyApp/Models/Subject.swift#L16) nullifies references to preserve history; [StudySession](../studyApp/Models/StudySession.swift#L90) cascades owned children. [SessionViewerViewModel](../studyApp/ViewModels/SessionViewerViewModel.swift#L24) deletes individually and protects only the live ID |
| Independent store verification | [SwiftDataIntegrityTests](../studyAppTests/SwiftDataIntegrityTests.swift#L93) refetch from fresh contexts with autosave disabled and [reopen a disk store](../studyAppTests/SwiftDataIntegrityTests.swift#L246). [StudyItem TestContainer](../studyAppTests/StudyItems/Support/TestContainer.swift#L10) reuses `AppSchema`; not every test container does, so do not claim universal schema parity |
| Honest experimental boundary | [FocusLabHost](../studyApp/Views/Dev/DesignLab/FocusLabHost.swift#L14) owns mock state; [SettingsView](../studyApp/Views/Settings/SettingsView.swift#L80) gates its debug entry. Promote a design by adapting its real state/accessibility behavior, not by copying the mock session |

## Follow-through in the requested order

1. **Codebase quality:** Land focused source corrections above in normal app branches through `dev`, then promote. Highest-impact work is deletion recovery, persistence error UX and truthful timing/data. The final-subject repair is a small first correction, not a substitute for the rest. Timer replay (#234) and StudyItem editor work (#231) remain separate scopes; this audit does not certify those branch implementations.
2. **Gating:** Make review/build/device evidence attributable to the exact candidate, and require the chosen checks on the branches that accept it. Live repository protections are a separate owner audit; this source review makes no claim that a documented checklist is currently enforced remotely.
3. **Lint:** Keep the [narrow existing rules](../.swiftlint.yml) for mechanically enforceable mistakes. Lint cannot establish a truthful total, a recoverable save, VoiceOver traversal, or large-type layout. New rules should follow corrected examples and a demonstrated repeatable error; lint work (#233) and CI tooling (#232) are separate.
4. **Owner-curated repository skills/docs:** Point agents at the good files above and correct stale samples when their owning behavior changes. Preserve the `AGENTS.md`/`CLAUDE.md` parity rule. Reconcile existing guidance rather than layering conflicting instructions; docs cleanup (#230) is separate.
5. **Tests:** Extend the existing pure timing, ownership and fresh-context persistence checks at the specific missing seams; use focused device checks for accessibility/layout. [The shared test plan](../studyApp.xctestplan) enables unit tests and disables the legacy UI target. No new broad UI suite or Xcode run was needed to establish these source findings.

Documentation-only verification: every linked path and line was checked against the baseline; inventory and reachability were inspected with file/reference searches. No app source changed in this audit.
