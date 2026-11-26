# Sessions history

The list of past study sessions, with a detail view and bulk removal.

## Sub-features

- A list of sessions, where each row is a `NavigationLink` to `SessionDetailView`.
- The **Remove Sessions** toolbar button, which is destructive. It does not ask for confirmation on `dev` yet. The active session is never deleted.

## How to get to it (user POV)

Tap the **Sessions** tab. The navigation title is `Sessions`.

## Driving it with xcodebuildmcp

1. Tap the `Sessions` tab, then wait for the `Sessions` navigation title.
2. Snapshot it, tap the first row, and wait for the detail view.
3. Go back. To test removal, tap **Remove Sessions**, and confirm if a dialog appears.

## Proof

- The rows match sessions created earlier in the run.
- After removal and a relaunch, the list is empty, except for any session that was still running. That one remains.

## Gotchas

- Removal is permanent for the simulator's data. Only use it on sessions this run created.
