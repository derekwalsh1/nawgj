# NAWGJ Expense Tracker — Modernization Backlog

This backlog tracks the incremental modernization of the app. It's meant to be
updated as we go — check items off, add notes, and re-prioritize as needed.

**Agreed approach:** incremental, screen-by-screen. Stay UIKit + storyboards
for existing screens; adopt SwiftUI for screens as they get rewritten. Small,
ongoing steps rather than a big-bang rewrite.

## Phase 1 — Foundation
- [x] Adopt `UIWindowSceneDelegate` / scene-based app lifecycle (removes the
      "UIScene lifecycle will soon be required" warning). `SceneDelegate.swift`
      wired into the Xcode target, `Info.plist` updated with
      `UIApplicationSceneManifest`, `AppDelegate` updated with scene session
      configuration methods. Verified with a Debug build.
- [x] Sweep for and resolve any other deprecation warnings surfaced by Xcode.
      A full clean build produced no compiler warnings/deprecation notices
      beyond an unrelated App Intents metadata extraction message.
- [x] Add a small helper/pattern for hosting a SwiftUI view from a
      `UIHostingController` so future SwiftUI screens can be pushed from
      existing storyboard segues. See `SwiftUIHosting.swift`
      (`pushSwiftUIView` / `presentSwiftUIView` extensions on `UIViewController`).

## Phase 2 — Safety net
- [x] Add unit tests around fee/expense calculations (`Fee`, `Expense`,
      `MeetDay` billing/rounding logic, mileage & lodging rules) before doing
      any structural refactors, so behavior changes are caught early.
      Added `FeeTests.swift`, `ExpenseTests.swift`, `MeetDayTests.swift`,
      `MeetMileageRateTests.swift` (25 tests total). Also wired the
      previously-orphaned `NawgjExpenseTrackerTests` target into the project
      (it had no files in its Sources build phase and a stale `TEST_HOST`
      pointing at the wrong product name, so it never actually ran before).
      Run with:
      `xcodebuild -project NawgjExpenseTracker.xcodeproj -scheme NawgjExpenceTracker -configuration Debug test -destination 'platform=iOS Simulator,name=16Pro'`
  - **Bug found while writing tests, now fixed (user sign-off given):**
    `Meet.getMileageRate(forDate:)`'s fallback comparators were inverted from
    their doc comments/intent:
    - A meet date **after** the last table year (currently 2026) returned the
      **earliest** rate (2016, 0.54) instead of the most recent one.
    - A meet date **before** the earliest table year (2016) returned the
      **latest** rate (2026, 0.725) instead of the earliest one.
    Fixed by correcting the comparators to `{ $0.key < $1.key }` in both
    `max(by:)`/`min(by:)` calls, so out-of-range dates now correctly fall
    back to the most recent (post-table) or earliest (pre-table) rate as the
    doc comment always intended. Tests renamed to
    `testGetMileageRate_forYearAfterTable_returnsMostRecentRate` and
    `testGetMileageRate_beforeEarliestTableYear_returnsEarliestRate` in
    `MeetMileageRateTests.swift`, all passing.

## Phase 3 — First SwiftUI screen (pilot)
- [x] Pick one small, low-risk, storyboard-driven screen (e.g. a judge
      detail/level form) and rebuild it in SwiftUI, hosted via
      `UIHostingController` and reached through the existing segue. Confirms
      the data-flow pattern from `JudgeListManager` / `MeetListManager` into
      SwiftUI views.
  - Chose the "Create Judge" screen (`CreateJudgeViewController` /
    storyboard scene `geV-cw-jcf`) as the pilot: small, self-contained, no
    fee/billing logic, and reached from a single call site
    (`AddJudgesToMeetViewController`'s "Create New Judge" button).
  - Added `NawgjExpenseTracker/JudgeList/CreateJudgeView.swift`, a SwiftUI
    `Form` with a Name field and a wheel `Picker` for `Judge.Level`, matching
    the old screen's validation/behavior exactly (Done disabled unless the
    name is non-empty and not already a duplicate judge; same default level
    selection logic).
  - `AddJudgesToMeetViewController` now pushes it via
    `pushSwiftUIView(...)` (from `SwiftUIHosting.swift`, Phase 1) with a
    closure-based `onFinish` callback instead of the old unwind segue —
    pops the nav stack and refreshes the judge list/table on completion.
  - Removed the old `CreateJudgeViewController.swift` file, its storyboard
    scene, and the button's old `show` segue connection in
    `Main.storyboard`; fully retired rather than left as dead code.
  - Bumped `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 for both the app
    and test targets (Debug/Release) since `Form` section headers,
    `.toolbar`, `.navigationTitle`, and `textInputAutocapitalization` all
    require iOS 14/15+. Given the app's current era, this is a low-risk,
    easily-reversible build setting change, not a business-logic change.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    tests still passing), plus installing and launching the app on the
    16Pro simulator to confirm it starts without crashing.
  - **Known limitation:** this environment has no UI-automation tooling
    (no `idb`/`cliclick`, and `osascript`/System Events lacks Accessibility
    permission), so the actual "Create New Judge" tap-through flow could
    not be exercised end-to-end by the agent. Please manually smoke-test:
    Select Judges → Create New Judge → enter a name/level → Done adds the
    judge and returns to Select Judges; Cancel returns without adding one.
- [x] UX revamp of `CreateJudgeView` (post-pilot polish): auto-focus the
      name field on appear (`@FocusState`), show an inline red duplicate-
      judge warning banner above the form instead of silently disabling
      Save, display the selected level's hourly rate in the picker's
      section footer (`Judge.Level.fullDescription`), trim leading/
      trailing whitespace from the name before validating/saving, and
      disable autocorrection/enable `.words` capitalization on the name
      field. Verified with the user directly in the simulator.
- [x] Consolidated the two separate "add/edit judge" screens into one
      shared `CreateJudgeView`. Previously, the top-level Judges tab
      ("All Judges" → "Add New" / tap a judge row) used an entirely
      separate, unmodified UIKit screen, `JudgeInfoDetailsTableViewController`
      — distinct from the meet-scoped "Select Judges" → "Create New Judge"
      flow that already used `CreateJudgeView`. This caused confusion when
      testing (bug reports against the old screen were mistaken for bugs in
      the new one).
  - Gave `CreateJudgeView` a `Mode` enum (`.create` / `.edit(JudgeInfo)`).
    In edit mode it pre-populates name/level from the existing judge, skips
    the duplicate-name check (matching the old screen's edit behavior —
    only a non-empty name is required), saves via
    `JudgeListManager.updateSelectedJudgeWith(...)` instead of `addJudge(...)`,
    and shows the judge's current name as the navigation title instead of
    "Create Judge". The toolbar button is now labeled "Save" in both modes
    (was "Done" in create-only mode) for consistency.
  - `JudgeListTableViewController` now pushes `CreateJudgeView` via
    `pushSwiftUIView(...)` for both the "Add New" button and row-tap-to-edit,
    instead of the old `AddJudge`/`ShowDetail` storyboard segues.
    `JudgeManagementCell` gained an `addNewJudgeButton` outlet so the
    controller can wire the tap target in code.
  - Removed `JudgeInfoDetailsTableViewController.swift`, its storyboard
    scene ("Judge Info"), the `AddJudge`/`ShowDetail` segues, and the
    `unwindToJudgeInfoList` unwind action — fully retired, same pattern as
    the original `CreateJudgeViewController` removal.
  - **Storyboard editing gotcha hit and fixed:** removing a `<segue>` also
    requires removing its dangling `<segue reference="ID"/>` entry in the
    document-root `<inferredMetricsTieBreakers>` section, or Xcode/`ibtool`
    fails to unarchive the storyboard at all (not just a warning). See
    `/memories/repo/storyboard-editing.md` for the debugging recipe.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), plus installing and launching on the 16Pro simulator
    for manual smoke-testing of both entry points.

## Phase 4 — Expand SwiftUI screen-by-screen
- [x] Convert the "New Meet" / Meet Overview screen
      (`MeetDetailViewController`) to a SwiftUI `MeetDetailView` — a full
      screen conversion (info fields, Export/Generate Report actions, Meet
      Days/Judges navigation rows, and the per-day/per-judge fee summary
      table), per explicit user scope decision.
  - This screen doubles as both the "create" and "edit" flow for a `Meet`
    (unlike the earlier Judge screens, which were two separate classes) —
    since `Meet` already distinguishes a brand-new meet via its default
    `"New Meet"` name, `MeetDetailView` doesn't need a `Mode` enum like
    `CreateJudgeView` did; one view handles both cases.
  - Because `Meet` is a reference type (`class ... : Codable`) and Phase 5
    made manager saves cheap/non-blocking, `MeetDetailView` persists on
    every field change (`.onChange` → mutate `meet` directly →
    `MeetListManager.updateSelectedMeetWith(meet:)`) instead of replicating
    the old screen's `viewWillDisappear`-triggered save timing. Simpler and
    removes an entire class of "did we save before navigating away" bugs.
  - The summary/fee table (previously `MeetSummaryTableViewDelegate`) was
    reimplemented natively in SwiftUI (`ForEach` over days/judges) rather
    than wrapped, since the original logic was simple enough.
  - `MeetDetailView` still navigates to three screens that remain UIKit
    (`MeetDayTableViewController`, `JudgeTableViewController`,
    `JudgePDFViewController` for "Generate Report") via an explicit
    `pushViewController: (UIViewController) -> Void` closure supplied by
    the presenting `MeetTableViewController`, since a SwiftUI `View` has no
    `navigationController` of its own. Each of those three storyboard
    scenes was given a `storyboardIdentifier` (`MeetDayTable`,
    `MeetJudgeTable`, `MeetReport`) so they can be instantiated
    programmatically instead of via a segue.
  - `MeetTableViewController` now pushes `MeetDetailView` programmatically
    for both "add" (`+` bar button, now wired to a plain `@objc` action
    instead of a segue) and row-tap-to-edit (`didSelectRowAt`), with an
    `onFinish` closure that pops, reloads meets, and refreshes the table —
    replacing the old `AddItem`/`ShowDetail` segues and the
    `unwindToMeetListWithSender:` unwind action trigger point.
  - Removed `MeetDetailViewController.swift`, its "Meet Overview" storyboard
    scene, the `AddItem`/`ShowDetail` segues, and the now-orphaned
    `leftBarButtonItem` + unwind-segue + exit-placeholder trios in both
    `MeetDayTableViewController`'s and `JudgeTableViewController`'s scenes
    (each previously unwound to `MeetDetailViewController`'s
    `unwindToMeetDetailsWithSender:`, which no longer exists) — those
    buttons now fall back to the default system back button. Cleaned up
    the matching dangling entry in `<inferredMetricsTieBreakers>` for the
    replaced `AddItem` segue ID, per the established storyboard-editing
    lesson.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator for manual
    smoke-testing.
  - **Bug fix (post-conversion):** "Generate Report" silently did nothing
    because `generateReport()` cast the "MeetReport" storyboard scene to
    `JudgePDFViewController` (a *different*, per-judge PDF screen that
    force-unwraps `getSelectedJudge()!`) instead of `PDFViewController` (the
    scene's actual `customClass`, which builds a whole-meet report via
    `MeetPDFCreator`). Fixed the cast; `JudgePDFViewController` itself is
    unrelated to this screen and was left untouched. Lesson: always verify
    a storyboard scene's actual `customClass=` attribute before casting an
    instantiated view controller — don't infer the class from the scene's
    name/purpose. See `/memories/repo/storyboard-editing.md`.
- [x] Convert the Meet List root screen (`MeetTableViewController`) to a
      SwiftUI `MeetListView`, redesigned (not just ported) per explicit user
      request for better UX:
  - Compact rows (name, date + location, cost) with a status badge —
    priority-ordered: "N unpaid" (red) if any of the meet's judges aren't
    paid, else "Upcoming" (blue) or "Past" (gray) based on `startDate`.
  - Meets are sorted by date (most recent first) instead of manual
    drag-to-reorder; added `.searchable` search over name/location.
  - "New Meet" and "Import Meet…" combined into a single toolbar menu
    (previously import had its own permanent table row); import now uses
    SwiftUI's native `.fileImporter` and calls
    `MeetListManager.importMeet(fromFile:)` directly instead of duplicating
    its decode logic (as the old `MeetTableImportExportCell` did).
  - `.swipeActions` replaces the old Edit-mode/reorder flow for delete,
    resolving the tapped `Meet` back to its real index in
    `MeetListManager`'s array via `===` reference-equality lookup (`Meet`
    has no natural stable ID; added a minimal `Meet: Identifiable`
    conformance based on `ObjectIdentifier` for `List`/`ForEach`).
  - Adopts the Phase 5 async manager APIs (`loadMeetsAsync()`/
    `loadJudgesAsync()`) in a `.task` modifier — the first screen to do so,
    fulfilling the Phase 5 deferred-adoption item below.
  - Since the Meet List is the app's actual root screen (not pushed from
    another view controller), `SceneDelegate` now builds the UI hierarchy
    programmatically instead of via `storyboard.instantiateInitialViewController()`:
    it creates an empty `UINavigationController` first, defines
    `pushViewController`/`popViewController` closures that capture it
    weakly, constructs `MeetListView` with those closures, wraps it in a
    `UIHostingController`, then assigns `navigationController.viewControllers`
    — avoiding a circular-initialization problem.
  - Removed the storyboard's "NAWGJ Meet Manager" (Meet List) and
    "Navigation Controller" scenes entirely, along with the document's now
    -unused `initialViewController` attribute; verified with `ibtool
    --compile` afterward.
  - Deleted `MeetTableViewController.swift`, `MeetTableViewCell.swift`,
    `MeetTableImportExportCell.swift`, and the already-dead
    `MeetSummaryTableViewDelegate.swift` (confirmed via grep to have zero
    remaining references anywhere), and updated `project.pbxproj`
    accordingly.
  - `LaunchScreen.storyboard` intentionally left untouched — it has its own
    stale, inert duplicate of the old Meet List scene, but launch
    storyboards are only ever rendered as a static snapshot, never
    instantiated as live view controllers, so it doesn't affect
    compilation or runtime behavior.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator for manual
    smoke-testing.
- [x] **Post-conversion fix:** the Meet List redesign above removed the old
      "Judges" entry point that used to live inside the old
      `MeetTableViewController` scene, leaving no way to reach the Judges
      screen. Added a `.navigationBarLeading` toolbar button (`person.2`
      icon, labeled "Judges") to `MeetListView` that pushes the Judges
      screen via a new `showJudgeList()` method.
- [x] **Bug fix:** the "All Judges" screen had a non-functional, eyesore
      checkmark (`systemItem="done"`) button in the top-left nav bar. It was
      wired to an `unwindToMeetListWithSender:` unwind segue targeting an
      `<exit>` placeholder that belonged to the old Meet List/
      `MeetTableViewController` scene, already deleted in the conversion
      above — a "dangling storyboard connection" (distinct from, but
      similar in symptom to, the earlier `customClass=` mis-cast bug: both
      cause a button tap to silently do nothing). Removed the button,
      segue, and exit placeholder from the storyboard; confirmed via grep
      that no other scene shares the same unwind action name. Verified with
      `ibtool --compile`.
- [x] Convert the "All Judges" screen (`JudgeListTableViewController` /
      `JudgeManagementCell`) to a SwiftUI `JudgeListView`, matching the
      Meet List's list/row/swipe-to-delete/menu conventions:
  - Rows show the judge's name and `Judge.Level.fullDescription`; tapping a
    row pushes the existing `CreateJudgeView` in `.edit(judgeInfo)` mode
    (calling `JudgeListManager.selectJudgeInfoAt(_:)` first, since
    `CreateJudgeView`'s save-in-edit-mode logic depends on
    `selectedJudgeIndex` already being set).
  - `.swipeActions` for delete, resolving the tapped `JudgeInfo` back to
    its real array index via `===` reference-equality (added a minimal
    `JudgeInfo: Identifiable` conformance based on `ObjectIdentifier`, same
    pattern as `Meet: Identifiable` in `MeetListView`).
  - Toolbar menu combines "New Judge" (pushes `CreateJudgeView` in
    `.create` mode), "Import Judges…" (`.fileImporter` →
    `JudgeListManager.importJudges(fromFile:)`, which already handles
    security-scoped resource access internally), and "Export Judges" (JSON
    encode → share sheet).
  - `ActivitySheet` (the `UIViewControllerRepresentable` wrapper around
    `UIActivityViewController` used for the share sheet) was made
    non-private in `MeetDetailView.swift` so `JudgeListView` could reuse it
    instead of duplicating the wrapper.
  - `MeetListView.showJudgeList()` now pushes `JudgeListView` (wrapped in a
    `UIHostingController`) instead of the old storyboard scene.
  - Removed the "All Judges" storyboard scene, `JudgeListTableViewController.swift`,
    and `JudgeManagementCell.swift` entirely (storyboard scene already had
    its dangling checkmark/unwind segue removed in the fix above); updated
    `project.pbxproj` accordingly. `LaunchScreen.storyboard`'s stale inert
    duplicate scene intentionally left untouched, same rationale as the
    Meet List conversion.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator for manual
    smoke-testing.
- [x] Applied a NAWGJ brand color scheme (navy + gold), sampled from the
      header/footer of [nawgj.org](https://nawgj.org/) via browser
      screenshots (no scraping/automation of third-party data, just a
      visual color reference):
  - Added an `AccentColor` color set (`images.xcassets/AccentColor.colorset`,
    gold ≈ `#CBA135`) — the reserved asset-catalog name that both UIKit's
    default `tintColor` and SwiftUI's default accent color pick up
    automatically app-wide with no code changes, so it applies to the new
    SwiftUI screens and any remaining UIKit ones alike.
  - Added an `NAWGJNavy` color set (`images.xcassets/NAWGJNavy.colorset`,
    navy ≈ `#142542`) and applied it as the navigation bar's background via
    `UINavigationBarAppearance` in `AppDelegate.configureAppearance()`
    (opaque navy background, white title/large-title text, white bar
    button tint) — mirrors the site's dark navy header with light text,
    while leaving the gold `AccentColor` for in-content buttons/highlights.
    Applies globally since `UINavigationBar.appearance()` affects every
    screen's nav bar, old and new.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing) and installing/launching on the 16Pro simulator;
    please do a visual pass since color accuracy/contrast can't be judged
    from a build log alone.
- [ ] Continue converting screens outward from simple list/detail screens
      toward more complex ones, keeping the manager singletons as the
      source of truth so old and new screens can coexist mid-migration.
      **Agreed order (work one at a time, build+test+install after each):**
  1. [x] `MeetDayTableViewController` / `MeetDayDetailViewController` → new
         `MeetDayListView.swift` / `MeetDayDetailView.swift`.
  2. [x] `JudgeTableViewController` / `JudgeDetailViewController` (the
         per-meet judge fee list/detail, not to be confused with the
         already-converted "All Judges" `JudgeListView`) → SwiftUI.
  3. [x] `FeeTableViewController` / `FeeDetailsViewController` → new
         `FeeListView.swift` / `FeeDetailView.swift`. Also added a new
         manual rate override feature — see detail below.
  4. [x] `ExpensesTableViewController` / `ExpenseDetailsViewController` /
         `LodgingExpenseDetailsViewController` → SwiftUI. **(Done out of
         order** — user asked for Expenses before Fees. All 3 screens are
         now fully converted — see detail below.)
  5. [x] `AddJudgesToMeetViewController` / `AddJudgeFromInsideMeetViewController`
         → new `AddJudgesToMeetView.swift` — see detail below.
         (`AddJudgeFromInsideMeetViewController.swift` turned out to be
         dead code, not even referenced in `project.pbxproj` — deleted
         outright, no conversion needed.)
  6. [x] `JudgePDFViewController` (per-judge PDF report) → new
         `JudgeInvoiceView.swift` — see detail below.
  7. [ ] Then return to the two Phase 5 deferred items below (protocol
         abstractions, migrating remaining UIKit call sites to async APIs).

  **Step 1 detail (`MeetDayListView`/`MeetDayDetailView`) — done:**
  - Added `NawgjExpenseTracker/MeetDays/MeetDayListView.swift` (list of a
    meet's days, swipe-to-delete, "We noticed some things..." warning
    section reimplemented as computed properties mirroring the old
    `checkForMeetDayWarnings()`) and `MeetDayDetailView.swift` (a `Mode`
    enum — `.add(Meet)` / `.edit(MeetDay)` — following the `CreateJudgeView`
    convention, with native `DatePicker`/segmented `Picker`/`Slider`
    controls replacing the old expand/collapse-row pickers).
  - Preserved exactly: add-mode default construction (reuse last day's
    date+1/start/end time with 0 breaks and default 30-min break time if
    `meet.days` is non-empty; otherwise a 7am–5pm day from `meet.startDate`
    if empty), end-time auto-bump to start+15min, and the date-collision
    check/revert-with-alert behavior (excluding the day being edited).
    Deliberately dropped the old dead-code date-change side effect that
    shifted `startTime`/`endTime` by the picked date's day/month/year
    deltas (confirmed harmless per the research notes below).
  - `MeetDay` gained an `Identifiable` conformance (`ObjectIdentifier`),
    same pattern as `Meet`/`JudgeInfo`.
  - `MeetDetailView` gained a `popViewController: () -> Void` parameter
    (threaded through from `MeetListView.showMeetDetail()`) so
    `showMeetDays()` can push `MeetDayListView` (wrapped in
    `UIHostingController`) instead of instantiating the old storyboard
    scene; this same `popViewController` plumbing is reused as-is for the
    next step (`JudgeTableViewController` → SwiftUI).
  - Removed `MeetDayTableViewController.swift`, `MeetDayDetailViewController.swift`,
    their two storyboard scenes ("Meet Days Table View Controller" /
    `storyboardIdentifier="MeetDayTable"`, and "Meet Day Details"), the
    `ShowDetail`/`AddItem`/`unwindToDayList` segues, and the matching
    dangling `<segue reference="HbJ-xx-d82"/>` entry in
    `<inferredMetricsTieBreakers>` (per the established storyboard-editing
    lesson). Updated `project.pbxproj`: repurposed the existing (previously
    virtual/nameless) "MeetDay" `PBXGroup` into a real path-based "MeetDays"
    folder group, matching the `JudgeList` folder convention.
  - **New gotcha hit and fixed:** giving `MeetDayListView` a private stored
    property (`dateFormatter`) with no explicit `init` caused Swift's
    synthesized memberwise initializer to become `private` too (its access
    level matches the most restrictive stored property), so the call site
    in `MeetDetailView` failed with "initializer is inaccessible due to
    'private' protection level". Fixed by adding an explicit `init(meet:
    pushViewController:popViewController:)`. Lesson: any new SwiftUI view
    with a `private` stored property needs an explicit `init` if it's
    constructed from another file.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator for manual
    smoke-testing. Please manually smoke-test: Meet Overview → Meet Days
    and Times → add/edit/delete a day, confirm date-collision alert and
    warning banners appear as expected.

  **Step 2 detail (`MeetJudgeListView`/`MeetJudgeDetailView`) — done:**
  - Added `NawgjExpenseTracker/MeetJudges/MeetJudgeListView.swift` (the
    per-meet judges list, sorted by name to match the old `viewDidLoad`
    resort-in-place behavior, swipe-to-delete now properly persisted via
    `MeetListManager.removeJudgeAt(index:)` instead of the old code's
    un-persisted direct array mutation, "+" toolbar button pushing the
    still-UIKit `AddJudgesToMeetViewController` via storyboard identifier
    `"SelectJudges"`, and a paid-row highlight using semantic `Color.green`
    (adapts to light/dark mode) instead of the old hardcoded neon
    `seafoam()` UIColor, to match the app-wide convention of only using
    system/semantic colors established by the other converted screens)
    and `MeetJudgeDetailView.swift` (name/level/notes
    form, paid/meet-referee/W9/receipts toggles with immediate
    save-on-change persistence, and inline "Judge Fees"/"Judge Expenses"
    summary sections that fully replace the old
    `JudgeSummaryTableViewDelegate`).
  - **Key gotcha handled this step:** `FeeTableViewController`,
    `ExpensesTableViewController`, and `AddJudgesToMeetViewController` all
    relied on storyboard **unwind segues** whose target selectors
    (`unwindToJudgeDetailsWithSender:`, `unwindToJudgeListWithSender:`)
    were implemented on `JudgeDetailViewController`/`JudgeTableViewController`
    — both now deleted. Since their SwiftUI replacements are hosted in a
    generic `UIHostingController` that doesn't implement those selectors,
    the old unwind connections would have crashed at runtime. Fixed by:
    adding a plain `onFinish: (() -> Void)?` closure property to
    `AddJudgesToMeetViewController` (replacing its `performSegue(withIdentifier:
    "unwindToJudgeList", ...)` calls), and a plain
    `backButtonTapped(_:)` → `navigationController?.popViewController(animated:)`
    `IBAction` on `FeeTableViewController`/`ExpensesTableViewController`
    (replacing their unwind-based back buttons). This is a recurring
    pattern for every remaining item in this backlog whose parent screen
    becomes SwiftUI-hosted — check for unwind segues into the screen being
    replaced before deleting it.
  - Added `storyboardIdentifier`s (`SelectJudges`, `ManageFees`,
    `ManageExpenses`, `JudgeInvoice`) to the `AddJudgesToMeetViewController`,
    `FeeTableViewController`, `ExpensesTableViewController`, and
    `JudgePDFViewController` storyboard scenes so `MeetJudgeListView`/
    `MeetJudgeDetailView` can instantiate and push them directly.
  - Removed the old "Judges" and "Judge Details" storyboard scenes
    entirely, along with `JudgeTableViewController.swift`,
    `JudgeDetailViewController.swift`, `JudgeSummaryTableViewDelegate.swift`,
    and `JudgeTableViewCell.swift`. Updated `project.pbxproj`: added a new
    `MeetJudges` folder group (mirroring the `MeetDays` group convention)
    and removed the stale build file/file reference/sources entries for
    the four deleted files.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator. Please
    manually smoke-test: Meet Overview → Judge Fees and Expenses → add a
    judge via "Select Judges", tap a judge → Judge Details → toggle
    Paid/Meet Referee/W9/Receipts, change Level, edit Notes → navigate to
    "Adjust Fees"/"Manage Expenses"/"Invoice" and back without crashing,
    confirm fee/expense totals refresh, and delete a judge via swipe.

  **Step 4 detail (`ExpensesListView`) — done, list screen only:**
  - Added `NawgjExpenseTracker/Expenses/ExpensesListView.swift`: one row per
    expense category (Mileage, Meals, Tolls, Airfare, Transportation,
    Parking, Lodging, Other Expenses) showing its current total via
    `Expense.getExpenseTotal()`, in the same order as the old storyboard
    cells. Old bitmap category icons (`gas-40.png`, `meals-40.png`, etc.)
    were swapped for SF Symbols (`fuelpump.fill`, `fork.knife`, `road.lanes`,
    `airplane`, `car.fill`, `parkingsign`, `bed.double.fill`,
    `ellipsis.circle.fill`), matching the SF Symbol convention already
    used in `MeetDetailView`.
  - Tapping a row still pushes the existing UIKit `ExpenseDetailsViewController`
    (7 non-lodging types) or `LodgingExpenseDetailsViewController` (Lodging)
    via new `storyboardIdentifier`s (`ExpenseDetails`, `LodgingExpenseDetails`)
    added to their storyboard scenes — full SwiftUI conversion of those two
    detail screens (with their mileage-rate/lodging-cap math and expand/
    collapse date-picker rows) is deferred to a later pass, consistent with
    how `AddJudgesToMeetViewController`/`FeeTableViewController` were left
    as UIKit when the Judge screens were converted. Defensive fallback
    preserved from the old `prepare(for:)`: if a Lodging/Other expense is
    somehow missing from `judge.expenses`, one is created on demand (in
    practice every `Judge` is created with all 8 expense types up front,
    so this should never trigger).
  - **Same recurring unwind gotcha, again:** both detail screens' Cancel/Done
    buttons unwound via `unwindToExpenseListWithSender:` to an exit owned by
    `ExpensesTableViewController`, which this step deletes. Fixed by adding
    an `onFinish: (() -> Void)?` closure to both `ExpenseDetailsViewController`
    and `LodgingExpenseDetailsViewController`, removing their old
    segue-triggered `prepare(for:sender:)` save-on-Done logic, and replacing
    the storyboard's unwind-segue button connections with plain
    `cancelButtonTapped:`/`doneButtonTapped:` `IBAction` connections (Done
    saves via `saveExpense()` then calls `onFinish`; Cancel just calls
    `onFinish`, matching the old Cancel-also-navigates-back behavior).
  - Removed the "Expenses" storyboard scene, `ExpensesTableViewController.swift`,
    and the matching dangling `<segue reference="RYQ-14-ag2"/>` entry in
    `<inferredMetricsTieBreakers>`. Updated `project.pbxproj`: swapped the
    old file's build file/file reference/sources entries for
    `ExpensesListView.swift` in the existing `Expenses` folder group.
  - `MeetJudgeDetailView.showExpenses()` now constructs `ExpensesListView`
    and pushes it wrapped in `UIHostingController` instead of instantiating
    the old storyboard scene.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator. Please
    manually smoke-test: Manage Expenses → tap each of the 8 categories,
    edit an amount/date/notes, confirm mileage rate auto-lookup/manual
    override still work, confirm lodging total/nights entry still computes
    correctly, Cancel vs. Done both navigate back correctly without
    crashing, and totals refresh on return.

  **Step 4 follow-up (`ExpenseDetailView`/`LodgingExpenseDetailView`) — done, both detail screens:**
  - Added `NawgjExpenseTracker/Expenses/ExpenseDetailView.swift` (replaces
    `ExpenseDetailsViewController`, covering the 7 non-Lodging types) and
    `NawgjExpenseTracker/Expenses/LodgingExpenseDetailView.swift` (replaces
    `LodgingExpenseDetailsViewController`). Both are `Form`-based screens
    reusing the same SF Symbol icon per type as `ExpensesListView`, with a
    Cancel/Done toolbar. `ExpenseDetailView` has an Amount/Miles field, a
    conditional Mileage Rate section (toggle for manual override + rate
    field, auto-recalculated via `Meet.getMileageRate(forDate:)` when the
    date changes and the rate isn't manually overridden), a Date
    `DatePicker`, and a Notes `TextEditor`. `LodgingExpenseDetailView` has a
    Total($) field, a Nights `Stepper` (0...365), Date `DatePicker`, and
    Notes; on Done it back-computes `expense.amountPerNight = total /
    nights` (preserving the existing `getExpenseTotal()` lodging-cap
    formula in `Expense.swift`, which was NOT modified).
  - **Deliberate UX improvement over the old code:** both new screens stage
    all edits in local `@State` and only call
    `MeetListManager.GetInstance().updateSelectedExpenseWith(expense:)` on
    Done; Cancel discards everything. The old
    `LodgingExpenseDetailsViewController` mutated `expense.amountPerNight`
    live on every keystroke via `UpdateUIComponents()`, so its Cancel button
    didn't actually revert that one field — this is fixed (lower-risk,
    more predictable) in the new version.
  - Confirmed `ExpenseDetailsViewController`'s embedded lodging-handling
    branch (`isLodgingExpense`, `privateRoomRequestedSwitch`,
    `nightlyRateTextField`, etc.) was dead code in practice — `.Lodging`
    expenses always routed through the separate
    `LodgingExpenseDetailsViewController` scene via the
    `ShowLodgingExpenseDetails` segue — so it was correctly NOT replicated.
  - `ExpensesListView.rowTapped(_:)` now pushes these two new SwiftUI views
    (wrapped in `UIHostingController`) instead of instantiating the old
    UIKit storyboard-identified controllers.
  - Removed the "Expense Details" and "Lodging Expense Details" storyboard
    scenes entirely (no dangling segue/tie-breaker references were left
    behind — both scenes' only connections were plain `action`s, not
    `segue`s), and deleted `ExpenseDetailsViewController.swift` /
    `LodgingExpenseDetailsViewController.swift`. Updated `project.pbxproj`:
    swapped both old files' build file/file reference/sources-phase entries
    for `ExpenseDetailView.swift`/`LodgingExpenseDetailView.swift` in the
    existing `Expenses` folder group.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator. Please
    manually smoke-test: Manage Expenses → tap each of the 8 categories,
    edit an amount/date/notes, confirm mileage rate auto-lookup/manual
    override still work, confirm lodging total/nights entry still computes
    correctly, Cancel vs. Done both navigate back correctly without
    crashing, and totals refresh on return.

  **Step 3 detail (`FeeListView`/`FeeDetailView`) — done, plus new manual rate override feature:**
  - Added `NawgjExpenseTracker/Fees/FeeListView.swift` (one row per
    meet-day fee, showing date + "Hours: X - Total Fees: $Y" matching the
    old cell format) and `NawgjExpenseTracker/Fees/FeeDetailView.swift`
    (Date/Total Time/Break Time/Billable Time/Judge's Rate/Fee display
    rows, plus an "Adjust Judge's Time" toggle + wheel `Picker`s for
    hours/minutes, and a "Judge did not work this day" toggle).
  - **New feature — manual rate override:** `Fee` already had `rate` and
    `rateOverridden` properties, but the old `FeeDetailsViewController`
    never actually let the user edit them; it only ever *displayed*
    `judge.level.rate` and never persisted a rate back onto the fee (the
    stored `fee.rate` was only ever set at fee creation time and kept in
    sync with the judge's level via `Judge.changeLevel(level:)`). Added a
    new "Adjust Rate" toggle + Rate($) text field to `FeeDetailView` so a
    judge's rate can be manually overridden for a single fee, independent
    of their level's standard rate. Updated `Judge.changeLevel(level:)` to
    skip fees where `rateOverridden == true` when applying the new level's
    rate, so a manual override survives subsequent level changes instead
    of being silently wiped out.
  - This screen has no Cancel option, matching the old UIKit screen (its
    "Fee List" back button unwound and saved unconditionally via
    `prepare(for:sender:)`) — `FeeDetailView` persists changes immediately
    via `persistFee()` on every toggle/field change, the same live-save
    convention used by `MeetDetailView`/`MeetJudgeDetailView`, rather than
    the Cancel/Done staging pattern used by the Expenses detail screens
    (which did have a Cancel button in the old code).
  - `MeetJudgeDetailView.showFees()` now constructs `FeeListView` and
    pushes it wrapped in `UIHostingController` instead of instantiating the
    old storyboard scene via the `ManageFees` storyboard identifier.
  - Removed the "Fees" and "Fee Details" storyboard scenes entirely (no
    dangling segue/tie-breaker references left behind), and deleted
    `FeeTableViewController.swift`/`FeeDetailsViewController.swift`.
    Updated `project.pbxproj`: swapped both old files' build file/file
    reference/sources-phase entries for `FeeListView.swift`/
    `FeeDetailView.swift` in the existing `Fees` folder group.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), a clean `ibtool --compile` check of the edited
    storyboard, and installing/launching on the 16Pro simulator. Please
    manually smoke-test: Adjust Fees → tap a fee, toggle "Adjust Judge's
    Time" and change hours/minutes, toggle "Adjust Rate" and enter a
    manual rate, toggle "Judge did not work this day", confirm the Fee
    total updates correctly for each combination, navigate back and
    confirm the fee list total refreshes, and confirm changing the judge's
    level elsewhere does NOT overwrite a manually-overridden fee rate.

  **Step 5 detail (`AddJudgesToMeetView`) — done:**
  - Added `NawgjExpenseTracker/MeetJudges/AddJudgesToMeetView.swift`,
    replacing the storyboard-driven "Select Judges" screen
    (`AddJudgesToMeetViewController`). Shows the master judge roster
    (`JudgeListManager`) as a plain list with a checkmark for multi-select,
    disabling (and labeling "(Already Included)") judges already on the
    meet — matching the old screen's behavior exactly. "Create New Judge"
    pushes the existing `CreateJudgeView`, then pops back and refreshes the
    list, mirroring the old `createNewJudgeButtonTapped`. Cancel/Done
    toolbar buttons match the old screen; Done adds each selected judge to
    the meet via `MeetListManager.addJudge(judge:)` before calling
`onFinish()`.
  - `MeetJudgeListView.addJudges()` now constructs `AddJudgesToMeetView`
    directly instead of instantiating the old storyboard scene via the
    `SelectJudges` identifier.
  - Discovered `AddJudgeFromInsideMeetViewController.swift` was dead code —
    not referenced anywhere (no storyboard scene, no other source file, and
    critically not even present in `project.pbxproj`'s Sources build
    phase), meaning it was never even compiled into the app. Deleted it
    outright rather than converting it.
  - Removed the "Select Judges" storyboard scene entirely (verified no
    dangling segue/reference left behind), deleted
    `AddJudgesToMeetViewController.swift` (which also removed the
    now-unused `CheckableTableViewCell` helper class), and updated
    `project.pbxproj` (removed the now-empty `Judge` group, added
    `AddJudgesToMeetView.swift` to the existing `MeetJudges` group).
  - Verified with `xcodebuild build` + `xcodebuild test` (25 passing) +
    `ibtool --compile` (clean) + simulator install/launch.

  **Step 6 detail (`JudgeInvoiceView`) — done:**
  - Added `NawgjExpenseTracker/PDFConversion/JudgeInvoiceView.swift`,
    replacing the storyboard-driven "Invoice" screen
    (`JudgePDFViewController`). PDF generation itself is unchanged
    (`JudgePDFCreator.createPDFFrom(judge:meet:atLocation:)`, still
    `PDFKit`/`UIPrintPageRenderer`-based) — only the *presentation* screen
    was converted to SwiftUI: a `PDFKitRepresentedView`
    (`UIViewRepresentable` wrapping `PDFView`, same display settings as the
    old screen) plus a share button that presents a `UIActivityViewController`
    (via a small `ActivityView`/`PDFActivityItemSource` wrapper) preserving
    the old custom email subject line ("Invoice and Details for
    <Judge_Name>").
  - `MeetJudgeDetailView.showInvoice()` now constructs `JudgeInvoiceView`
    directly instead of instantiating the old storyboard scene via the
    `JudgeInvoice` identifier.
  - Removed the "Invoice" storyboard scene entirely (it was the last scene
    in `Main.storyboard` — verified no dangling references), deleted
    `JudgePDFViewController.swift`, and updated `project.pbxproj`.
  - Verified with `xcodebuild build` + `xcodebuild test` (25 passing) +
    `ibtool --compile` (clean) + simulator install/launch. Please manually
    smoke-test: Select Judges → add an existing judge and create a brand
    new judge from that screen, then Invoice → confirm the PDF renders and
    the share sheet opens with the correct file/subject.

## Phase 5 — Concurrency & manager cleanup
- [x] Move `JudgeListManager` / `MeetListManager` file I/O to `async/await`.
  - Both managers' actual disk I/O (`JSONEncoder().encode` + `Data.write`,
    `Data(contentsOf:)` + `JSONDecoder().decode`) is now done through real
    `async` functions (`saveJudgesAsync`/`loadJudgesAsync`/
    `loadAndSortJudgesAsync` on `JudgeListManager`; `saveMeetsAsync`/
    `loadMeetsAsync` on `MeetListManager`), instead of blocking the calling
    thread synchronously.
  - The existing synchronous public API (`saveJudges()`, `loadJudges()`,
    `saveMeets()`, `loadMeets()`, etc.) is preserved byte-for-byte in
    behavior and signature, so **no external call sites needed to change** —
    `saveJudges()`/`saveMeets()` now just kick off the async write in a
    `Task` instead of writing inline. This was deliberately scoped to avoid
    a risky, wide-blast-radius rewrite of every view controller that reads/
    writes through these singletons.
  - Added a `pendingSaveTask` chain in each manager so that if multiple
    saves are triggered in quick succession, their async writes still
    complete in the same order they were requested (a fire-and-forget
    `Task` per call, on its own, doesn't guarantee ordering across
    concurrent tasks — this closes that gap).
  - `MeetListManager`'s meet-day/fee UUID synchronization logic (previously
    inline in `loadMeets()`) was extracted into a shared
    `decodeAndNormalizeMeets(from:)` helper so both the sync and async load
    paths behave identically without duplicating that logic.
  - New `...Async()` APIs are intended for adoption by new/converted SwiftUI
    screens going forward (e.g. via a `.task { }` modifier), rather than
    retrofitting existing UIKit screens — see the deferred item below.
  - Verified with a full `xcodebuild build` and `xcodebuild test` run (all
    25 tests passing), plus installing and launching on the 16Pro
    simulator.
- [ ] Consider protocol-based abstractions for the managers so they're
      mockable in tests, once enough of the UI has moved off synchronous call
      sites.
- [ ] _Deferred:_ migrate existing UIKit view controllers'
      `loadJudges()`/`loadMeets()`/`loadAndSortJudges()` call sites (in
      `viewDidLoad`/`viewWillAppear`, currently synchronous) to the new
      `...Async()` APIs. Not done now because it would require touching
      every screen that reads these managers at load time — better done
      naturally as each screen is converted to SwiftUI in Phase 4.
      `MeetListView`'s `.task` modifier is the first adopter of
      `loadMeetsAsync()`/`loadJudgesAsync()`; remaining UIKit screens are
      still on the synchronous APIs.

---
_Last updated: 2026-07-26 — Phase 4: converted the "All Judges" screen
(`JudgeListTableViewController`/`JudgeManagementCell`) to SwiftUI
(`JudgeListView`), applied the NAWGJ navy/gold brand color scheme, and fixed
a pre-existing git case-collision bug between two differently-cased
`images.xcassets` trees on the `modernization` branch (consolidated, no data
loss, verified with a clean build). Spelled out the agreed, ordered plan for
the remaining screen conversions above (Meet Days → per-meet Judge/Fee →
Fee editing → Expenses → Add-Judges-to-Meet → PDF report), plus captured
detailed research/decisions for the next screen up
(`MeetDayTableViewController`/`MeetDayDetailViewController` →
`MeetDayListView`/`MeetDayDetailView`) so that work can resume without
re-deriving it. Next up: implement `MeetDayListView.swift` and
`MeetDayDetailView.swift` per the research notes above, wire them into
`MeetDetailView.showMeetDays()` (adding a `popViewController` param to
`MeetDetailView`), remove the old scene/files, and verify with build+test+
simulator install._
