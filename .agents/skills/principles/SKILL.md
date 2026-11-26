---
name: principles
description: Engineering principles for this Swift/SwiftUI repo, one section each. Covers laziness, root causes, attacking the premise, proving it works, verifiable units, testing behaviour, modelling the domain, type discipline, migrate-then-delete, experience first, and encoding lessons. Read the relevant section when brad-behaviour, gated-loop or another skill names it.
disable-model-invocation: true
---

# Principles

Read only the section you need. Each one opens with when it applies.

## laziness

*Applies when you size a diff, refactor, or are tempted to add an abstraction or layer.*

- Make the smallest change that solves the problem. Fewer lines beat elegant boilerplate.
- Put a decision in one place and pass the result along. Do not repeat the same choice in several files.
- Remove dead code, stub references and redundant checks before you build on top of them.

## fix-root-causes

*Applies when debugging.*

Fix the fault, not the place where it surfaced. The root cause is the first place the system did something it should not do.

- Reproduce first. Ask "why" until the answer is a wrong decision in the code. When stuck, add logging and read the actual state.
- Ask whether the state that triggered the symptom is legitimate. If it is, handle it where the code broke. If it should never exist, find what produced it. Usually a guard, `try?`, clamp or retry at the symptom hides the bug.
- Fix the pattern, not the instance. Search for every place with the same fault.

## attack-the-premise

*Applies when two or more fixes that share one premise have failed the same gate.*

- Write the premise down: the one sentence every failed fix assumed.
- Test it before writing another fix. Find an observation that would come out differently if the premise were false, and make it.
- Do not start the next fix until the premise is written down and tested.

## prove-it-works

*Applies after a task, before you say "done".*

Check the real thing: run the feature, read the value, or inspect the diff. "It compiles", a self-report or a cached result does not count. When a check fails, suspect the way you observed it before the system. Script the check when you can, so it can run again.

## sequence-verifiable-units

*Applies to multi-step work, and to how you order commits and PRs.*

Order work as small units that each end in a state you can check. Do not move on until the current unit's gate passes. The **gated-loop** skill runs this. Deliver in the order that proves the work: the failing test, then the fix; the removal, then the reshape.

## test-behaviour

*Applies when you write, change or keep a test.*

A test asserts what callers can observe: return values, thrown errors, state they can read back, and what was saved. Private helpers and call order are implementation. Judge each test against two imagined edits:

- **Break the behaviour.** If the test still passes, it proves nothing.
- **Change the internals** but keep every observable result. If the test fails, it is pinned to the implementation.

Keep tests that catch the first edit and survive the second. In this repo, persistence tests use an isolated `ModelContainer`, and timing tests use an injected clock.

## model-the-domain

*Applies to stateful logic, or code that keeps growing branches.*

Encode the domain in a type instead of scattered conditionals:
- an `enum` with associated values in place of several booleans;
- a state machine for session phases;
- a lookup table or registry in place of a `switch` that is copied into several files.

The sign you skipped this is a second boolean that must stay in sync with the first. Do not force it when the code is small, local and unlikely to grow.

## type-discipline

*Applies when designing types or a signature.*

- Make impossible states impossible to write. Prefer a non-optional property with a default over an optional that is "never nil in practice".
- Give values that share a primitive type but mean different things their own type, such as a subject code versus a display name.
- Parse external data, such as JSON, `UserDefaults` and launch arguments, at the boundary into a typed model. Trust internal types after that.
- Handle every `enum` case. Avoid `default:` on enums you own, so that a new case fails to compile.

## migrate-then-delete

*Applies when a new internal API replaces an old one, for example JSON stores replaced by SwiftData.*

Move every caller to the new API and delete the old one in the same wave. Do not keep compatibility layers for internal code. Update tests to assert the new contract, and delete tests that only protect the old implementation.

## experience-first

*Applies to product, UX and scope tradeoffs.*

When implementation convenience conflicts with a better experience, choose the experience. Ship fewer features with polished details over more rough ones: transitions, spacing, feedback and error states. Every control must earn its place in the core loop of studying and focusing.

## encode-lessons

*Applies when you write the same instruction a second time, or keep getting the same correction.*

Turn the lesson into structure: a SwiftLint custom rule, a type, a test, or a script. Write it as prose only when it needs judgment, and then add an example of the failure. The **self-correction** skill runs this.

Adapted from the principle skills in [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
