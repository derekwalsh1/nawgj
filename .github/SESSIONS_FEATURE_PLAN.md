# Feature plan: concurrent Sessions within a Meet Day

Branch: `feature/multi-floor-sessions` (off `modernization`).

## Goal

Bigger meets can run multiple apparatus areas concurrently on the same
calendar day (e.g. two floors running in parallel, judges split across
them). Today the app only models one continuous time range per `MeetDay`,
and assumes **exactly one `Fee` per (judge, day)**. This feature introduces
a `Session` concept so a day can have one or more sessions, each with its
own start/end/break time, and each judge is billed per session they
actually worked.

## Decisions already agreed with the user

1. **Terminology**: call the concept **`Session`** in code and UI (avoids
   clashing with "Floor" as a gymnastics apparatus name).
2. **Overlap rule**: a judge can work multiple sessions in a day, but
   **cannot** be assigned to two sessions whose times overlap (can't be in
   two places at once). Must validate on assignment.
3. **Migration**: fully automatic. Existing `MeetDay`s (no sessions concept)
   get a single implicit `Session` synthesized from their existing
   start/end/breaks at load time. No user action required, no data loss.
4. **Fee granularity**: one fee line per **session** (not per day). Invoices
   naturally already iterate `judge.fees` directly, so this is mostly just
   giving each fee a session reference and label.
5. **Session naming**: free-text (e.g. "Vault/Bars", "Session 1", whatever
   the user types) — not a fixed enum.
6. **UI visibility**: the sessions list is **always shown** on the day
   screen, even when a day has only one session (no hidden/implicit-mode
   UI). Simpler and more consistent than conditionally hiding it.
7. **Judge-to-session assignment UI**: a checklist on the session screen
   (same pattern as the existing "Select Judges" screen used to add judges
   to a meet).
8. **Auto-assignment default**: preserved from today's behavior, generalized
   to sessions — adding a new judge to the meet auto-assigns them to every
   existing session (creates a fee for each); adding a new session
   auto-assigns every existing meet judge to it (creates a fee for each).
   The checklist is there to *remove* people who didn't actually work a
   given session (e.g. because of an overlap, or they simply didn't judge
   that one), not as the only way to get assigned.

## Data model changes

### New `Session` model (`NawgjExpenseTracker/Session.swift`)
Mirrors `MeetDay`'s time/billing math almost exactly:
```swift
class Session: Codable {
    var name: String                 // free text, required (default "Session 1")
    var startTime: Date
    var endTime: Date
    var breaks: Int
    var breakTimeInMins: Int?
    var uuid: String?

    func totalTimeInHours() -> Float
    func breakTimeInHours() -> Float
    func totalBillableTimeInHours() -> Float
    func getUUID() -> String
}
```
To avoid duplicating `MeetDay`'s rounding/billing math, extract the shared
logic into a small protocol (e.g. `BillableTimeRange`) with a default
extension implementation, and have both `MeetDay` (for its legacy fields,
kept for migration) and `Session` conform. `MeetDay.totalBillableTimeInHours()`
etc. stop being "this day's own range" and become **sums across its
sessions** (see below), so the protocol is really just for `Session` and the
one-time migration read of `MeetDay`'s legacy fields.

### `MeetDay` changes
- Add `var sessions: [Session] = []`.
- Keep the legacy `startTime`/`endTime`/`breaks`/`breakTimeInMins` stored
  properties **only** for backward-compatible decoding of old JSON — they
  stop being the source of truth once `sessions` is populated.
- Custom `init(from decoder:)`: decode as today, then if `sessions` is
  empty/missing, synthesize exactly one `Session` from the day's legacy
  start/end/breaks/breakTimeInMins (uuid = a fresh UUID). This happens
  in-memory only; the next save naturally persists the new `sessions` array
  (same "touch UUID on load" pattern `decodeAndNormalizeMeets` already uses
  elsewhere).
- `totalTimeInHours()` / `totalBillableTimeInHours()` become the sum over
  `sessions`.
- New helper: `hasOverlap(_ candidate: Session, excluding: Session?) -> Bool`
  — used by the assignment-overlap check.

### `Fee` changes
- Add `var sessionUUID: String?` alongside the existing `meetDayUUID`
  (keep `meetDayUUID` too — cheap, avoids having to walk sessions to find
  the parent day for date-based lookups/reports).
- `getSessionUUID()`/`setSessionUUID(uuid:)` accessors, mirroring the
  existing `meetDayUUID` accessors.

### Normalization / migration (`MeetListManager.decodeAndNormalizeMeets`)
Extend the existing per-meet normalization pass:
1. For each `MeetDay`, ensure it has ≥1 `Session` (handled by `MeetDay`'s
   custom decoder above, but double-check here too — cheap and defensive).
2. Replace the current "ensure every judge has exactly one fee per day"
   logic with "ensure every judge has exactly one fee per **session**"
   (matched by `sessionUUID` instead of `meetDayUUID`), applying the
   agreed **auto-assign-all** default: a fee missing for a (judge, session)
   pair gets created automatically, same as today's per-day behavior.
   This also naturally handles the migration case: since every old day
   becomes exactly 1 session, and old fees get their `sessionUUID` filled
   in by matching on `meetDayUUID` (each day had exactly one fee per judge
   before, and now has exactly one session, so the mapping is 1:1 and
   unambiguous) — no fees are lost or duplicated.

## Business logic changes (`Meet.swift`)

- `addMeetDay(day:)`: day starts with one default `Session` (full day's
  time range as today), then auto-creates a fee for every existing judge
  for that session (same shape as today, just keyed by session).
- New `addSession(to day: MeetDay, session: Session)`: auto-creates a fee
  for every existing meet judge for the new session (subject to the
  overlap rule — if a judge already has an overlapping session that day,
  skip auto-assigning them and surface that in the UI so the user knows
  who wasn't auto-included).
- New `assignJudge(_ judge: Judge, to session: Session, in day: MeetDay) -> Result<Void, AssignmentError>`
  (or similar) — validates no overlapping session already assigned for
  that judge that day, then creates the fee. Returns/throws a clear error
  if blocked, for the checklist UI to surface.
- New `unassignJudge(_ judge: Judge, from session: Session)` — removes that
  one fee.
- `addJudge(judge:)`: auto-assign the new judge to every existing session
  across every day (was: every day).
- `removeMeetDay(at:)`: remove fees for all of that day's sessions (was:
  fees matching the day's UUID directly).
- New `removeSession(_:from:)`: remove fees tied to that session's UUID.
- `meetDayChanged(atIndex:)` → rename/refactor to `sessionChanged(_:in:)`,
  triggered when a session's own time range changes (not the day): re-sync
  non-overridden fees' hours/date for that specific session only.
- `judgesFeeForDay(dayIndex:judge:)`: change from `fees.first(where: date == )`
  to summing all fees whose session belongs to that day (`.filter(...).reduce`).
- `Judge.getFeesFor(date:)`: same fix — sum instead of `first`.

## UI changes

- **`MeetDayListView`** (day list): mostly unchanged — still one row per
  day, but the hours subtitle becomes the sum across sessions (already
  works if `MeetDay.totalBillableTimeInHours()` is updated as above).
  Consider showing session count in the row subtitle, e.g. "3 sessions •
  8.5 hrs", when there's more than 1.
- **`MeetDayDetailView`** (day detail, currently the start/end/breaks
  editor): becomes a lighter screen — just the meet date, plus a **List of
  Sessions** for that day, "+" to add a session. Tapping a session pushes
  the new `SessionDetailView`. Delete-day behavior unchanged (still removes
  all sessions + their fees).
- **New `SessionDetailView`**: reuses ~90% of the current
  `MeetDayDetailView`'s time-editing UI code (name field is new; start
  time/end time/breaks/break-length controls carry over almost verbatim),
  plus a new **"Judges Working This Session"** checklist section (same
  interaction pattern as `AddJudgesToMeetView`). Toggling a judge on/off
  calls `assignJudge`/`unassignJudge`; a blocked overlap toggle shows an
  alert naming the conflicting session.
- **`FeeListView`** (per-judge fee list): still one row per fee, but the
  row label needs the session name when a day has >1 session — e.g. "July
  4, 2026 — Vault/Bars" vs. just "July 4, 2026" when there's only one
  session that day (avoids visual noise for the common single-session
  case).
- **`MeetDetailView`** ("Meet Days and Times" summary rows / per-day cost):
  no visible change expected beyond the `judgesFeeForDay` sum fix above.
- **PDF reports** (`JudgePDFCreator.swift`, `MeetPDFCreator.swift`): both
  already iterate `judge.fees` directly, so per-session line items mostly
  fall out "for free" — just need the date/label cell to include the
  session name when the parent day has >1 session (same rule as
  `FeeListView`, keep it consistent). `MeetPDFCreator`'s per-day judge
  filter (`getFeesFor(date:)`) fix (sum, not `first`) is required so a
  judge who only worked one of several sessions that day still shows up
  correctly.

## Testing plan
- New `SessionTests.swift`: billing-hours math (mirror `MeetDayTests.swift`
  cases), overlap detection.
- Extend `MeetDayTests.swift`: legacy-JSON migration produces exactly one
  session with matching hours; day-level totals sum sessions correctly.
- New tests for `Meet.assignJudge`/`unassignJudge`/overlap rejection.
- Extend `ManagerMockingTests.swift`-style coverage if the normalization
  logic in `MeetListManager` needs direct testing (may need to expose a
  testable seam for `decodeAndNormalizeMeets`, currently `private static`).
- Full regression: existing `FeeTests`/`ExpenseTests`/`MeetMileageRateTests`
  must keep passing unchanged (they don't touch sessions, but the shared
  `MeetDay`/`Fee` model changes must not break them).

## Suggested implementation order (checklist)
- [x] `Session` model + shared billing-time protocol/extension.
- [x] `MeetDay` sessions array + legacy-decode migration + day-level sums.
- [x] `Fee.sessionUUID` + accessors.
- [x] `MeetListManager` normalization: per-session fee sync (replaces
      per-day sync), with unit tests.
- [x] `Meet.swift` business logic: `addSession`, `assignJudge`/`unassignJudge`,
      overlap validation, `sessionChanged`, fixed `judgesFeeForDay`/
      `getFeesFor`, updated `addMeetDay`/`addJudge`/`removeMeetDay`.
- [x] `SessionDetailView` (new) + judges checklist.
- [x] `MeetDayDetailView` refactor to host the sessions list.
- [x] `MeetDayListView` subtitle tweak (session count/hours).
- [x] `FeeListView` row label tweak (session name when >1 per day).
- [x] PDF report tweaks (`JudgePDFCreator`, `MeetPDFCreator`).
- [x] Tests (unit + full regression) + manual smoke test on simulator.
- [x] Update `MODERNIZATION_BACKLOG.md`/repo memory once shipped.

## Open risks / things to double-check while implementing
- `decodeAndNormalizeMeets` is `private static` in `MeetListManager` —
  may want a package-internal seam for direct unit testing rather than only
  testing through full load/save round-trips.
- Need to decide exact wording/UX for the overlap-rejection alert, and
  whether removing/shrinking a session's time after judges are already
  assigned should re-validate and possibly auto-unassign judges who no
  longer fit (edge case — flag for user decision when we get there).
- Deleting the *last* session in a day: should probably be blocked (a day
  must always have ≥1 session) rather than silently leaving a day with zero
  sessions and zero billable hours.
