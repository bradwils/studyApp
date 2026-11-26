# Subjects editor

Create and delete the subjects that sessions are tracked against.

## Sub-features

- Add a subject with a name and a code. The code is upper-cased on save.
- Each subject is listed as a row, `subjectRow_<CODE>`.

## How to get to it (user POV)

Tap the **Debug** tab, whose navigation title is `Settings`, then tap `editSubjectsButton`.

## Driving it with xcodebuildmcp

1. Tap the `Debug` tab, wait for the `Settings` title, then tap `editSubjectsButton`.
2. Tap `subjectNameField` and type `Maths`. Tap `subjectCodeField` and type `math101`.
3. Tap `addSubjectButton`.

## Proof

- A row `subjectRow_MATH101` exists.
- After a stop and relaunch, the row is still there.

## Gotchas

- `addSubjectButton` is disabled until both fields have text.
- The editor is reached through the Debug tab today. Update this route if it moves into user-facing settings.
