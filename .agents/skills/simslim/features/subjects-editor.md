# Subjects editor

Create and delete the subjects that sessions are tracked against.

## Sub-features

- Add a subject with a name of up to 32 characters and a code of up to 4. The code is upper-cased on save, and the field shows a live `n/4` counter.
- Each subject is listed as a row, `subjectRow_<CODE>`.
- The editor is a sheet with a **Close editor** button (`xmark`).

## How to get to it (user POV)

Tap the **Debug** tab, whose navigation title is `Settings`, then tap `editSubjectsButton`.

## Driving it with xcodebuildmcp

1. `touch` the `Debug` tab, wait for `editSubjectsButton`, then `touch` it. Wait for `subjectNameField`.
2. `touch` `subjectNameField`, then type `Maths`. Use `type-text`, or `key-sequence --key-codes 16 4 23 11 22`.
3. `touch` `subjectCodeField`, then type `math` with `key-sequence --key-codes 16 4 23 11`.
4. Take a fresh snapshot, then `touch` `addSubjectButton`.

## Proof

- `wait-for-ui --predicate exists --identifier subjectRow_MATH` succeeds, and the row shows `Maths` and `MATH`.
- After a stop and relaunch, the Focus tab shows **Current Subject: Maths**. The snapshot has a button labelled `Subject, Maths`.

Proven on 2026-11-26 on iPhone 17 running iOS 27.0, with every step above.

## Gotchas

- `addSubjectButton` is disabled until both fields are valid. A code longer than 4 characters keeps it disabled and turns the counter red.
- Return in the code field does not reliably submit. It can be used up accepting the predictive suggestion. Press `addSubjectButton` instead.
- The editor is reached through the Debug tab today. Update this route if it moves into user-facing settings.
