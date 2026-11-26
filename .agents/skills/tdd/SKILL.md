---
name: tdd
description: "Use only when the user explicitly asks for TDD, a failing test or a regression test, OR when the bug has an obvious cheap local test target in studyAppTests. Skip when the test path is unclear, expensive, UI-heavy or not requested."
disable-model-invocation: true
---

# TDD bug fix

When a bug has a clear, cheap test path, make the broken behaviour executable before changing production code. The goal is a focused Swift Testing test that fails before the fix and passes after it.

Do not force a test when it would be impractical. Use the closest useful check instead if a test would need:
- broad setup or brittle mocks;
- a UI test. AGENTS.md forbids writing one unless the user asks;
- production-only state;
- vague reproduction steps.

## Workflow

1. **Understand the bug.** State the intended behaviour, the current behaviour, the affected path, and the smallest observable reproduction.
2. **Choose the narrowest check.** Prefer the existing suite for that code path in `studyAppTests/`. Use its patterns: an isolated in-memory `ModelContainer`, as in `StudyItems/Support/TestContainer.swift`, and an injected clock for timing.
3. **Write the failing test first.** Encode the intended behaviour, not the current implementation. See **test-behaviour** in **principles**.
4. **Run it before fixing,** and confirm it fails for the intended reason:
   ```bash
   xcodebuildmcp simulator test --project-path studyApp.xcodeproj --scheme studyApp --simulator-name "iPhone 17" --use-latest-os --extra-args "-only-testing:studyAppTests/<Suite>" --style minimal
   ```
   If it passes, or fails for another reason, fix the test before touching the implementation.
5. **Fix the bug** with the smallest production change.
6. **Rerun the same command** and confirm it passes.

The build rule in AGENTS.md allows these two test runs as gates. Do not run the whole suite unless the fix touches shared code.

## If a failing test is impractical

- Use the closest executable check instead:
  - a `swift` script for pure logic;
  - a **simslim** drive for UI behaviour;
  - a log assertion.
- Prefer no new test over a bad test. A bad test checks mocks, mirrors implementation details, or depends on wall-clock timing.

## Guardrails

- Never change a test to match a wrong implementation.
- Never weaken an existing assertion unless the expected behaviour has really changed and you say why.
- Keep the test focused on the bug.

## Reply

- The failing-before test and the failure it printed.
- The passing-after run.
- If you could not show a failing-before result, say why, and name the check you used instead.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
