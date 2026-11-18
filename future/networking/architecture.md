# Networking architecture

Status: **proposal, nothing built.** Written against `dev` at `06327e1`. The plan is meant to stay flexible: the backend vendor is swappable (see [The seam](#the-seam-one-network-module)), and the phases at the bottom can be reordered.

**iCloud / CloudKit sync is deferred to a later target** (see [Deferred: iCloud sync](#13-deferred-icloud-sync)). Personal data stays in the local SwiftData store for now.

---

## 1. What we're building

1. **Public study groups.** One per subject (official or custom). Semi-live: who is studying, how many, a daily leaderboard. Polled, not streamed.
2. **Private study rooms.** Paid by one person, up to 20 members. Near-real-time (about 5 s) presence, plus **lock-in**: members arm their own Screen Time shields together and release each other.

Non-goals for now: chat, free-text messaging, remote locking of a phone that is not running the app (see [Delivery reality](#6-delivery-reality-what-ios-allows)), and cross-device sync of personal data (deferred).

---

## 2. Principles

- **Personal data stays on the device; the server holds only what other people need to see.** Status, subject, session start, daily totals. Notes, location, scores and breaks never leave the phone.
- **Anchor dates, not heartbeats.** A studying phone is usually locked and cannot send pings. The server stores "studying since 14:02" and every viewer computes the timer locally. This mirrors `Stopwatch.adjustedStartTimeForAnchor`.
- **Presence is driven by transitions** (start, pause, resume, end), not by socket state.
- **The server is the only authority on votes and grants.** Phones never command each other directly.
- **Arming and emergency exit are local.** The two actions that must never fail do not depend on the server.
- **One seam.** Every view model talks to a protocol; one file imports the vendor SDK.

---

## 3. System overview

```
iPhone app
 ├─ SwiftData (local store)             personal data, plus caches of server data and the outbox
 └─ Services/Network ──HTTPS────────►  Postgres        profiles, subjects, rooms, presence, totals, lock-ins
                     ──WebSocket────►  Realtime        private rooms only, while the room is on screen
                     ◄──APNs─────────  Edge Function   break requests and votes for backgrounded phones
```

| Data | Lives in | Why |
|---|---|---|
| Study sessions, breaks, sections, notes, location, scores | Device (SwiftData) | Personal, and the server never needs it |
| User's own subjects, items, field definitions, tags | Device (SwiftData) | Personal |
| Official subject catalogue (HSC, SAT, IB...) | Server | Shipped to everyone; changes without an app update |
| Profile (handle, display name, avatar) | Server | Others must see it |
| Presence, daily totals, leaderboards | Server | Shared |
| Rooms, membership, invites, entitlements | Server | Shared, paid |
| Lock-in sessions, break signals, votes, grants | Server | Needs a single referee |
| `RemoteUser` rows, room snapshots | Device (SwiftData) | Cache of server data, safe to wipe |

Consequence of deferring iCloud: personal history lives on one device (and in that device's own backups). A reinstall or new phone starts without session history, but the server still has the user's profile, rooms and daily totals.

---

## 4. Server data model (Postgres)

| Table | Holds | Notes |
|---|---|---|
| `profiles` | id, handle (unique), display_name, avatar | `id` = Sign in with Apple identity |
| `subjects` | id, name, code, `curriculum` (`hsc`, `sat`, `ib`, `custom`), `owner_id` null for official | Custom ones are visible only to the owner unless a room uses them |
| `rooms` | id, kind (`public`/`private`), subject_id, owner_id, invite_code, max_members (20), `break_threshold`, paid_until | Public rooms are created by us, one per subject |
| `room_members` | room_id, user_id, role, `lock_consent` | Cap enforced in the join function, not the client |
| `presence` | user_id (pk), status, subject_id, `session_started_at`, `device_id`, changed_at | One row per user; written on transitions |
| `study_intervals` | id (client UUID), user_id, started_at, ended_at, received_at | Append-only; duration is computed server-side |
| `daily_totals` | user_id, day, seconds | Leaderboard source |
| `room_snapshots` | room_id, studying_count, top list (json), generated_at | One row read by everyone polling a public room |
| `lockin_sessions` | id, room_id, started_at, planned_end | One per group lock-in |
| `lockin_participants` | session_id, user_id, armed_until, state | Who is currently locked in |
| `break_signals` | session_id, user_id, level (`quiet`/`visible`), created_at | Counts toward the group threshold |
| `unlock_requests` | id, session_id, user_id, reason (preset), expires_at, outcome | Expires about 2 min after creation |
| `unlock_votes` | request_id, voter_id, vote | Unique per (request, voter) |
| `lock_events` | append-only audit log | Every signal, request, vote, grant, emergency |
| `devices` | user_id, device_id, apns_token | |
| `entitlements` | user_id, room_id, source, valid_until | App Store receipts verified server-side |
| `reports`, `blocks` | | Required for App Review once users can type handles and room names |

Row-level security: members read only their own rooms; `presence` and `daily_totals` are readable by fellow room members and public-room participants; writes go through functions, not direct table access.

---

## 5. Rooms

### Public rooms (polling)

- Clients call one endpoint, `GET /rooms/{id}/snapshot`, every 10 to 15 s while the screen is visible.
- A scheduled job rebuilds `room_snapshots` at the same interval. 700 viewers cost the same database work as 7.
- No sockets, no per-viewer queries.

### Private rooms (realtime)

- While the room screen is open, the client holds one Realtime channel for that room: presence changes, break signals, votes, grants.
- On leaving the screen the channel closes. A room with nobody looking costs nothing.
- Do **not** use the vendor's built-in "presence" feature for study status. It tracks the socket, which dies when the phone locks. Study status comes from the `presence` table.

---

## 6. Delivery reality: what iOS allows

| Target phone is... | How a message arrives | Speed |
|---|---|---|
| App open | Socket | about 1 s |
| App backgrounded | Visible push (alert) | usually seconds |
| App background push (`content-available`) | Silent push | **best effort, throttled** |
| App force-quit | Silent pushes are discarded by the system | next app open |

Consequences for the design:

- Anything that must reach a phone in the pocket uses a **visible** notification, with Approve / Decline actions so friends can vote from the lock screen.
- The person asking for something (an unlock) has the app open, so their grant arrives over the socket.
- **Cold remote lock is out of v1.** An open question is whether a notification service extension may apply a shield; it needs a one-day test on a real device before any marketing promises it.
- Network from the Screen Time extensions is possible but has no documented execution budget. Do not rely on it.

---

## 7. Lock-in and breaks

### How a lock-in starts and ends

1. Room owner or any member starts a lock-in with a planned end time.
2. Each participating phone **arms its own shield locally** with that end time (Family Controls). It releases itself at the end time, with no server involved.
3. The phone tells the server it is armed; presence shows `locked in`.

### Exit levels

| Level | Visible to | Effect |
|---|---|---|
| Quiet "I need a break" | Count only ("3 of 6") | Counts toward the group threshold |
| Visible "I want a break" | Badge on the member's card, plus the count | Counts toward the same threshold |
| "Let me out" | Everyone locked in gets Approve / Decline | Unlocks the requester for N minutes if approvals reach the threshold |
| Emergency | Room is alerted afterwards | Local unlock immediately, even offline; logged and shown to the room |

Quiet and visible signals together reaching the threshold trigger a **group break** for everyone.

### Defaults (all adjustable by the room owner)

- Threshold is a **fraction of people currently locked in**, not of all members. Default one half, minimum one. A 20-person room with 4 people locked in needs 2 approvals.
- Locked in alone: auto-approved.
- A "let me out" request expires after about 2 minutes and counts as declined.
- Reasons are preset choices, not typed text.
- The requester cannot approve their own request.

### Vote flow

```
requester ──request_unlock()──► server (single Postgres function, one transaction)
                                  ├─ insert unlock_requests
                                  ├─ notify locked-in members (visible push + realtime)
voters    ──cast_vote()───────► server
                                  ├─ insert unlock_votes (unique per voter)
                                  ├─ if approvals ≥ ceil(threshold × locked_in) → grant
                                  └─ write lock_events
requester ◄──grant {unlock_until}── realtime
requester phone: lift shield, schedule re-lock at unlock_until locally
```

The grant carries an absolute `unlock_until`. The phone schedules the re-lock locally, so it re-arms even with no signal.

---

## 8. iOS module structure

```
studyApp/
  Services/
    Network/
      StudyNetwork.swift        protocol the view models use
      SupabaseTransport.swift   the only file that imports the vendor SDK
      MockStudyNetwork.swift    previews and tests; replaces hard-coded sample data
      DTOs/                     wire types, separate from @Model classes
      Outbox.swift              queues transitions made offline, replays with idempotency keys
    ScreenTime/
      ShieldController.swift    the only file that imports FamilyControls / ManagedSettings
    Auth/
      AuthService.swift         Sign in with Apple, session refresh
  Extensions (targets)/
    ShieldAction, DeviceActivityMonitor, NotificationService
```

### The seam: one network module

```swift
protocol StudyNetwork: Sendable {
    func publish(_ transition: StudyTransition) async
    func publicRoom(_ id: RoomID) async throws -> RoomSnapshot
    func privateRoomEvents(_ id: RoomID) -> AsyncStream<RoomEvent>
    func send(_ command: LockCommand) async throws -> LockReceipt
}
```

- View models receive a `StudyNetwork` and never import the vendor. Moving to AWS or Cloudflare means rewriting one transport file.
- DTOs are plain `Codable` structs. `@Model` classes are never sent over the wire.
- The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so network types must be declared `nonisolated` or be actors, or every call hops through the main thread.
- `SocialFeedViewModel.sampleItems` and `SocialFeedItem` get replaced by `RemoteUser` / snapshot-backed state behind `MockStudyNetwork`.

### Hooks into existing code

| Existing | Change |
|---|---|
| `StudyTrackingViewModel.startSession / pauseSession / resumeSession / endSession` | Emit a `StudyTransition` to the network module (via the outbox) |
| `RemoteUser` | Local cache of `presence` rows; stays in the existing store |
| `GroupsView`, `SocialView` | Read from the network module |
| `studyApp.entitlements` (currently empty) | Push, Sign in with Apple, App Groups, Family Controls |

---

## 9. Identity

- **Sign in with Apple** is the identity. Its stable ID is `profiles.id`.
- With no iCloud sync, the server profile follows Apple sign-in and personal data follows the device.
- **One account, two devices.** `presence` has one row per user and carries a `device_id`. A second device starting a session asks "end it on the other device?".
- In-app account deletion is required by App Review: deleting a profile removes server rows. Local data stays on the device.

---

## 10. Cost

Verified against the vendor pricing pages on 2026-11-15; confirm before committing.

| Item | Supabase | Notes |
|---|---|---|
| Free | $0 | 200 concurrent sockets, 2 M realtime messages / month |
| Pro | $25 / month | 500 peak sockets included, then $10 per 1,000; 5 M messages included, then $2.50 per million |
| Push (APNs) | $0 | |
| Apple Developer | $99 / year | |

| Stage | Estimated monthly |
|---|---|
| Building and TestFlight | $0 |
| Launch, about 1k daily users | $25 |
| About 10k daily users | $50 to $100 |

The 10k row is an estimate, not a quote. Sockets are the cost driver, and only private-room screens hold one.

---

## 11. Alternatives considered

| Option | Verdict |
|---|---|
| **Supabase** (recommended) | Postgres, auth, realtime and edge functions in one place. Leaderboards and vote counting are SQL. |
| **AWS** | Cost is fine, but you wire Cognito, API Gateway, Lambda, a database, SNS and IAM yourself. Plain Postgres schema keeps a later move possible. |
| **Cloudflare Durable Objects** | Excellent fit for 20-person rooms (about $5 / month base, $0.15 per million requests beyond 1 M). You build auth and the database yourself. Revisit if socket cost grows. |
| **Firebase** | Push is built in; leaderboards and the vote function are awkward without SQL. |
| **CloudKit for everything** | Cannot enforce paid rooms or referee votes. |

---

## 12. Risks and open questions

| Risk | Mitigation |
|---|---|
| **Family Controls entitlement** is approved per bundle ID, and separately for each extension; takes days to weeks | Request now, before any code |
| Silent pushes are unreliable | Visible pushes for anything time-sensitive |
| Can a notification extension apply a shield? (untested) | Device test; v1 does not depend on it |
| Leaderboard cheating via edited clocks | Server stamps receive time and computes duration; clamp outliers |
| Abuse of handles and room names | `reports` and `blocks` tables; moderation path before launch |
| Australian under-16 rules | The study app has no chat and is primarily for education; confirm with a proper legal check before launch |
| Offline sessions uploaded late | Outbox with client UUIDs as idempotency keys; server clamps timestamps to its receive-time window |

---

## 13. Build order

1. **Groundwork.** Family Controls entitlement request; shield test on a device.
2. **Identity and presence.** Sign in with Apple, profiles, publishing transitions, the outbox.
3. **Public rooms.** Official subject catalogue, per-subject rooms, snapshot polling, leaderboards.
4. **Private rooms.** Invites, 20-member cap, in-app purchase and entitlement verification.
5. **Lock-in.** Local arming, break signals, votes, emergency exit, visible pushes.
6. **Later.** Cold remote lock (if the device test allows it), room analytics, moderation tooling.
7. **Later target: iCloud sync** (see below).

---

## 13. Deferred: iCloud sync

Out of scope until after lock-in ships. The models in `dev` are **not** CloudKit-compatible today: `.unique` on `StudySession.id`, `StudyItem.id` and `Tag.key`; non-optional to-many relationships; missing inverses on `StudyBreak`, `StudySection` and `SessionLocation`; several properties with no declared default. Making them compatible is roughly two to three days, plus moving the in-progress session out of the synced store.

Two details matter for that later work:

- CloudKit's production schema is additive-only, and TestFlight builds are understood to use it. The first build with sync on fixes the field set permanently, so fix the models first and enable sync in one deliberate build.
- Real device testing signed into iCloud is the only way to surface schema errors; unit tests with `cloudKitDatabase: .none` will not.

### Guardrails to keep that later work cheap

While building everything above, avoid creating new problems for the sync step:

1. **No new `@Attribute(.unique)`** on any model. Use plain UUID ids and look up before insert.
2. **New to-many relationships are declared optional with an inverse**, and new properties get a declared default.
3. **Client-generated UUIDs** for anything sent to the server (the outbox needs them as idempotency keys anyway).
4. **Official subjects come from the server catalogue**, not seeded into the local store. A user's `Subject` stores a `catalogID` instead, so syncing later cannot duplicate them.
5. **Keep the in-progress session recoverable but distinct from finished history**, so moving it to a local-only store later is a small change.
6. **Cache models** (`RemoteUser`, room snapshots) carry no relationships to personal models, so they can be split into a local-only store later.
