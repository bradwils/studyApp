---
name: xc-documentation
description: Write concise Xcode-style (DocC) documentation comments on a Swift type and its significant children — summary, short overview, optional snippet, and non-obvious notes. Use when asked to document, add Quick Help to, or write docs for a model, view model, view, or other Swift type.
---

# xc-documentation

Adds `///` DocC comments so a type shows up in Xcode Quick Help (⌥-click), the completion popover, and the Documentation Viewer in the same shape as Apple's own pages (e.g. `TabView`).

**Default to short.** The reader is the developer who wrote the app. Say what the signature can't, and stop. If a section would only restate the declaration or the obvious wiring, omit it.

## How Xcode renders a comment

DocC reads `///` Markdown placed directly above a declaration:

| Comment part | Rendered as |
|---|---|
| First paragraph | **Summary** — shown in Quick Help, completion popover, and under the page title |
| Following paragraphs | **Discussion / Overview** |
| `## Heading` | Section headings inside the discussion |
| Fenced ```` ```swift ```` block | Syntax-highlighted code listing |
| ``` ``Symbol`` ``` | Clickable link to another symbol |
| `> Note:` `> Important:` `> Warning:` | Callout asides |
| `- Parameters:` / `- Returns:` / `- Throws:` | Method-only sections |

Only the first paragraph is a summary — one sentence or fragment, ≤150 characters, plain text, no links or other symbol names.

## Scope: what gets documented

- Document **the type named in the request**, plus its **significant children** (a relationship, a property with a constraint or side effect, a non-trivial init or method, a notable nested type).
- **Stop at one level.** If a child is itself a type with members, document the child's declaration only — do not descend into grandchildren.
- Skip trivially named members (`id`, `createdAt`, `taskName`). A property earns a comment only when it carries a delete rule, a nil-meaning, a default that surprises, or a side effect.
- Don't edit other types' files unless asked.

## Template

Use only the parts that earn their place. Most types need the summary, a sentence or two of overview, and one callout; a snippet only when usage isn't obvious.

````swift
/// One-sentence summary of what this type is.
///
/// ## Declaration
///
/// ```swift
/// @Model final class Subject
/// ```
///
/// What it does and why it exists, in one or two sentences. Include the
/// mechanism where it matters (e.g. how it persists, what it observes).
///
/// ```swift
/// let subject = Subject(name: "Mathematics", code: "MATH101")
/// context.insert(subject)
/// ```
///
/// > Important: Deleting a subject nullifies `StudySession.subject`; session
/// > history is kept.
@Model
final class Subject { ... }
````

### Guidance

- **Summary** — matches Apple's tone ("A view that switches between multiple child views using interactive user interface elements.").
- **Declaration** — directly after the summary, on the **type only** (not children). A fenced `swift` block with the signature stripped of the body: attributes, access, `final`, name, generics, and inheritance/conformances (e.g. `@Observable final class SubjectsEditorVM`). Always include it, even on small types. Copy it from the source; don't invent conformances.
- **Overview** — one or two sentences, slightly technical: name the mechanism (`@Relationship` delete rule, `@Observable` tracking, `@Query` source), not a restatement of the property list.
- **Snippet** — optional, 3–5 lines, compiles against the real API.
- **Notes** — only non-obvious, project-relevant behaviour: delete rules, persistence quirks, `@MainActor`, things callers must do manually (e.g. touching `updatedAt`), unimplemented pieces. One callout for the most important; at most two or three bullets.
- **Where It's Used / See Also** — **omit by default.** Never list trivial wiring such as "registered in `.modelContainer`" or "X references Y via `y`". Include only when the usage is surprising or the type belongs to a notable system worth linking.

## Children

One line each, summary only. Add a second line only for a constraint or side effect.

```swift
/// The subject this session was studied for, or `nil` once the subject is deleted.
var subject: Subject?
```

- Enum cases / constants: one concise line, or none if self-evident.
- Nested `private struct` views: skip.
- Methods: only when behaviour isn't obvious; use `- Parameters:` / `- Returns:` / `- Throws:` with internal names.

## Procedure

1. Read the type. Grep usages (`rg "TypeName" --type swift`) to confirm claims — don't guess — but don't report the usages in the docs unless they're surprising.
2. Match the tone of nearby doc comments; don't rewrite existing `///` unless asked.
3. Replace any `//` description comment with `///` rather than leaving both.
4. Put `///` above the attributes (`@Model`, `@Observable`), not between attribute and `class`.
5. Re-read: summary is one sentence, the declaration block matches the source signature, the prose doesn't restate it, every ``` ``link`` ``` target exists.

## Project rules that apply

- Follows [CLAUDE.md](../../../CLAUDE.md): comments explain non-obvious *why*. Doc comments are an explicit exception **only when this skill is invoked**.
- Models stay pure data: documenting must not add logging or logic.
- Don't build to check rendering unless asked; say a doc build wasn't run. For a preview: Product → Build Documentation (⌃⇧⌘D), or `xcodebuild docbuild -scheme studyApp -destination generic/platform=iOS`.

## Pitfalls

- A blank line between the `///` block and the declaration detaches the comment.
- ``` ``Symbol`` ``` links to symbols that don't exist silently render as plain text; don't invent targets.
- Fenced code needs a `swift` language tag.
- Callouts need the `> ` prefix on every line.
- No links or symbol names in the summary line.
- Don't restate the declaration ("A class that has a name and a code").

## References

- [Writing Symbol Documentation in Your Source Files](https://www.swift.org/documentation/docc/writing-symbol-documentation-in-your-source-files)
- [Formatting Your Documentation Content](https://www.swift.org/documentation/docc/formatting-your-documentation-content)
- [TabView](https://developer.apple.com/documentation/swiftui/tabview.md) — model page for structure and tone
