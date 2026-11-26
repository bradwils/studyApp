---
name: deslop
description: Remove AI-generated slop from a Swift/SwiftUI diff before commit, covering narrating comments, defensive code on trusted paths, force unwraps, type erasure, needless nesting and debug leftovers. Keeps DocC (///) comments. Use for /deslop, "clean up this diff", or before every commit under brad-behaviour.
disable-model-invocation: true
---

# Deslop

Remove slop that this branch introduced. Work in the main thread with no subagents. Keep behaviour unchanged unless you are fixing a clear bug, and say so when you do.

## Scope

The scope is the files the user names. Otherwise it is the branch diff against its base, including uncommitted changes:

```bash
git diff "$(git merge-base HEAD origin/dev)" -- '*.swift'
```

Touch only lines this diff added or changed. Leave pre-existing code alone, even when it has the same problems.

## Code

- **Defensive code on trusted paths.** Remove:
  - `guard`, `if let` or `try?` that handle a state the types already rule out;
  - silent `catch {}` blocks;
  - clamps or retries that hide a bug instead of handling a legitimate state.

  Keep checks at real boundaries: decoding, user input, `UserDefaults` and launch arguments.
- **Forcing past the type system.** Fix the type rather than force it. This covers `!`, `as!` and `try!` added to make code compile, `AnyView` used to dodge a `some View` return, and `Any` or `AnyObject` parameters.
- **Nesting.** Flatten nested `if` statements into `guard ... else { return }` early exits. AGENTS.md says `guard` is always a standalone statement.
- **One-caller wrappers.** Inline a helper, extension or protocol with one caller that adds nothing.
- **Leftovers.** Remove `print(`, `debugPrint(`, `dump(`, commented-out code, unused `import`s, `TODO`s with no owner or issue, and `fatalError("not implemented")`.
- **Layer leaks.** Move or remove `import SwiftUI` in `ViewModels/`, and `import SwiftUI` or `import os` in `Models/`.
- **Style drift.** Fix anything inconsistent with the file around it: naming, access control, `final class`, and the indentation style.

## Comments

AGENTS.md allows comments only for a non-obvious *why*. Delete these:

- comments that narrate what the next line does;
- banner and section-divider comments that add nothing a `// MARK:` doesn't;
- long justifications for a workaround in our own code. Mark the symbol to rename or reshape instead, and list it in the reply;
- `// DEV ONLY` line comments. Dev-only status belongs in the type's DocC, as below.

Keep these:

- **All `///` DocC comments.** The **xc-documentation** skill owns them. Do not shorten or remove them here.
- License or legal headers.
- A comment about behaviour forced by Apple, a framework bug or another dependency we cannot change, with a link or OS version when one exists.
- `// swiftlint:disable:next <rule>` with a reason, where the rule's catch is a false positive. A disable that hides a real force unwrap or force cast gets removed, and the code gets fixed.
- `// MARK:` lines.
- Issue or PR links that explain a constraint the code cannot express.

### Dev-only code

A type that exists only for development must say so in its DocC, not in a `//` comment. If the diff adds or touches such a type with no DocC marker, add this callout to its `///` block, or create a short block if it has none:

```swift
/// > Important: Dev only. Not part of any user flow; see "Developer-Only Views" in AGENTS.md.
```

For a dev-only control placed inside a real screen, put the same callout on the nearest `private var` or `private struct` that builds it.

## Reply

Give one to three sentences: what you removed, any behaviour you changed, and the symbols you flagged for a reshape. Then list any `// DEV ONLY` comments still in the scope that you converted.

Adapted from deslop in [cursor-team-kit](https://github.com/cursor/plugins/tree/main/cursor-team-kit) (MIT, Cursor) and no-comments in [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
