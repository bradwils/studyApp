# SwiftLint rules

`.swiftlint.yml` keeps the existing built-in correctness and naming checks and
adds narrow guards for mistakes this repository has already corrected. Custom
rules are errors. Intentional exceptions use `// swiftlint:disable:next <rule>`
with a nearby explanation; do not add a repository-wide baseline.

| Rule | Evidence and fix | Scope |
| --- | --- | --- |
| `no_swiftui_in_viewmodels` | The MVVM refactor (`e60fa11`) moved UI out of Models; the lint adoption (`1000a66`) enforced the layer boundary. Keep UI in Views. | Imports of the exact `SwiftUI` module in `studyApp/ViewModels/`, including indented, attributed and declaration imports. `SwiftUIX` is a different module. Logging remains allowed here. |
| `no_swiftui_in_models` | The same layer boundary keeps data Models free of UI and logging dependencies. Move presentation or logging to the appropriate View or ViewModel. | Exact `SwiftUI`, `os` and `OSLog` imports in `studyApp/Models/`; includes submodules and declaration imports. |
| `no_batch_delete_owned_records` | `9278d0c` fixed batch session deletion after integrity failures; `cc8f185` fixed the same pattern for StudyItems. Fetch the records, then call `context.delete(record)` for each so relationship deletion is applied to owned records. | Concrete `delete(model: StudySession.self)` and `delete(model: StudyItem.self)` calls in `studyApp/`, including multiline calls and `studyApp.` qualification. The inspector has the separate guard below to avoid duplicate diagnostics. |
| `no_batch_delete_in_model_inspector` | `DebugDataView` uses the generic model inspector for sessions as well as other models. Its confirmed Delete All now deletes each queried item, then saves once, just like its existing swipe deletion. Debug reset semantics still include every queried record. | Any `delete(model:)` call in `Views/Dev/DebugModelListView.swift`, including `Model.self`. |
| `injected_session_clock` | `a3d0cdd` replaced repeated `Date()`/`Date.now` reads with an injected clock in the session owner and Date parameters in timing values. Use `now()` in the owner and pass its timestamp to calculations. | Explicit `Date()`, `Date.init()` and `Date.now` reads in `StudyTrackingViewModel.swift`, `Focus/SessionTiming.swift` and `Focus/FocusTarget.swift` only. The default clock function reference `Date.init` remains valid. |

These are lexical guards, not Swift type or control-flow analysis. They do not
detect aliases, shorthand `.now`, comments inserted between expression tokens,
or calls hidden in helper functions. SourceKit's token filtering does not identify
Swift regex-literal bodies as strings: a regex containing guarded code can still
trigger these rules. Import guards anchor at a declaration line to avoid ordinary
single-line regex examples, but multiline regex content can resemble a declaration.
The batch guard does not resolve generic
types outside the known model inspector, and does not reject batch deletion of
other concrete model types. Session deletion's active-owner protection remains
covered by the integrity tests, not by this regex; the dev inspector deliberately
continues to offer a reset of all queried records.

There is no blanket ban on `@Published`: `SocialFeedViewModel` still uses
`ObservableObject`. Stored-context and state-ownership regexes were not added
because they cannot reliably distinguish local variables and preview state from
production ownership. Existing force-operation and fatal-error rules already
cover their respective patterns; custom rules do not duplicate them.

## Verify rules without building

Use the same SwiftLint **0.65.1** executable as CI, with a working SourceKit
runtime, and Python 3:

```bash
swiftlint version
python3 ci_scripts/test_swiftlint_rules.py
swiftlint lint --config .swiftlint.yml --no-cache
```

Pass `--swiftlint /path/to/swiftlint` to select a local executable. A standalone
binary that skips SourceKit-dependent rules fails the fixtures. CI uses
`ghcr.io/realm/swiftlint:0.65.1` and installs Python 3 in that container. It checks
fixtures before the normal repository lint. PRs into any branch are checked so
stacked PRs receive verification of their actual merge result. This adds lint
runs for matching changes in feature-target PRs; it keeps direct push runs limited
to `dev` and retains file filters. New fixture-only or runner-only changes also
trigger the workflow.

`ci_scripts/swiftlint_fixtures.json` contains source snippets with the same
directory paths the real config inspects. The Python runner copies the unchanged
config into temporary roots and invokes real SwiftLint, rather than reimplementing
the regexes in Python. It checks the complete diagnostic list for
each snippet, including rule ID, line, severity and source path. Positive cases
include the historical regressions; nearby valid cases cover comments, strings,
module/type name prefixes, injected clocks, model defaults, previews, tests,
individual deletion and generic batch calls outside the known inspector.

The fixtures focus on these custom rules and use the full, unchanged config, so
unexpected built-in or duplicate diagnostics also fail. The separate repository
lint checks all actual app and test files. Neither command compiles Swift or runs app
tests. `unused_import` still requires `swiftlint analyze` with compiler logs and
does not run in this workflow.
