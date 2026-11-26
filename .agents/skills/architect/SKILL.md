---
name: architect
description: "Sketch types, signatures and file placement before code, then stay in the loop while implementation fills in. Use for /architect, 'architect this', 'design this', or non-trivial work where jumping to code would lock in the wrong shape."
disable-model-invocation: true
---

# Architect

Before writing code, trace every part of the system the change touches. That covers Models, ViewModels, Views, tests, and the `.modelContainer` registration. Then sketch **two** different shapes for the change, giving for each:

- the types: `@Model` classes, `@Observable` view models, enums and value types;
- the signatures of each new or changed method, including where `ModelContext` is passed in;
- the files each piece lives in, following the layer rules in AGENTS.md.

Pick the shape where each piece of state has one owner, each task has one way to do it, and callers need to know least. Say in two lines why the other one lost.

If you keep adding workarounds while implementing, stop and redesign rather than patch.

Write the chosen sketch as Swift signatures with empty bodies in your reply, or in the PR's `## Why` for large work. Then implement against it. If the implementation forces a change to the sketch, say so.

Adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan (MIT).
