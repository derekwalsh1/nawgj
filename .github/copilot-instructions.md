# Copilot instructions for NAWGJ Expense Tracker

This repository contains NAWGJ Expense Tracker, an iOS app built with Swift and UIKit for managing meet expenses, judges, fees, and PDF reports.

## Project context
- The main Xcode project is `NawgjExpenseTracker.xcodeproj`.
- The app target is `NawgjExpenseTracker`, with most source under `NawgjExpenseTracker/`.
- The app uses UIKit, Foundation, PDFKit, MessageUI, and JSON-based persistence.
- The codebase follows a lightweight MVC pattern with storyboard-driven view controllers, table view cells, and model classes.

## Architecture and data flow
- The app is centered around a few core models: `Meet`, `MeetDay`, `Judge`, `JudgeInfo`, `Fee`, and `Expense`.
- Persistence is handled through the singleton managers `MeetListManager` and `JudgeListManager`, which save to files in the app’s documents directory (`Meets` and `Judges`).
- Selection state is also stored in these managers (`selectedMeetIndex`, `selectedJudgeIndex`, `selectedMeetDayIndex`, etc.), so changes to a screen often depend on the current selection being set correctly before navigation.
- Many screens are connected with storyboard segues and unwind segues rather than programmatic navigation.

## Business rules to preserve
- Fee and expense calculations are domain-specific and should not be changed casually.
- `MeetDay` handles billing time, break time, quarter-hour rounding, and minimum billing hours.
- `Fee` has override and exclusion behavior (`hoursOverridden`, `rateOverridden`, `exclude`) that is used by the fee detail screen.
- `Expense` has special logic for mileage and lodging calculations, including mileage rate lookup and single-room lodging caps.
- `Judge.Level` includes a fixed set of levels with associated hourly rates; changes here affect fee calculations and display text.
- `Meet` and `Judge` relationships are maintained through model arrays and fee objects that are synchronized when meets/days/judges are modified.

## UI and screen conventions
- The app is primarily storyboard-based and uses table view controllers for editing and detail flows.
- Preserve the existing pattern of expanding/collapsing rows for pickers (date/time pickers) and using `UITableView` updates for dynamic row heights.
- Keep the existing user-facing wording and labels where possible unless a change explicitly requires updated copy.
- Maintain accessibility and Dynamic Type support where the current UI already provides it.

## Coding conventions
- Follow the existing Swift style and naming in this repository.
- Prefer safe optional handling and `guard` statements over force unwraps.
- Preserve `Codable` compatibility and the current JSON structure unless a migration is explicitly requested.
- Use `os_log` for diagnostics instead of ad-hoc logging.
- Avoid introducing SwiftUI, Combine, or new third-party dependencies unless explicitly requested.
- Be careful with array/index access and guard against out-of-bounds access when modifying lists or selections.

## When editing features
- If a change affects models, review the related view controllers, managers, and any import/export or PDF-reporting flow.
- If a change touches meet-day or fee behavior, verify that associated judge fees are kept in sync.
- If a change impacts import/export or persistence, keep the JSON behavior backward-compatible where practical.
- If a change affects PDF generation, preserve the existing report structure and formatting.

## Import/export and reporting
- Import/export is handled with `UIDocumentPicker` and JSON files.
- PDF reports are generated with `PDFKit` and `UIPrintPageRenderer` using HTML content and custom formatting helpers.
- Preserve the existing workflow for exporting meets, judges, and generated reports.

## Validation
- Prefer Xcode-based validation when possible, such as building the `NawgjExpenseTracker` target.
- For changes to persistence, fees, expenses, or PDF generation, verify the relevant flow with a manual smoke test if possible.
- If a full build cannot be run in the current environment, note that limitation clearly.

## Clarification guidance
- No additional product requirements were found in the repository, so the safest default is to preserve current behavior and wording unless the request explicitly changes the app’s rules.
- If a requested change could affect billing logic, data compatibility, or key user workflows, ask for clarification before implementing it.
