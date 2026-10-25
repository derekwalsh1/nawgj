# What's New

## Version 5.3 (Build 38)

This update focuses on billing accuracy, judge list fixes, and new tools for meets with multiple sessions in a day.

- Fixed the 3-hour minimum billing rule to apply once per judge per day instead of once per session, so a judge working two short sessions on the same day is no longer double-billed the minimum.
- Fixed selecting one of two same-named judges (e.g. re-certified at a new level) also selecting/adding the other by mistake when adding judges to a meet.
- Added a bottom tab bar (Meets, Judges, Settings) and a bigger, clearer meet list.
- Added multi-select bulk delete on the All Judges screen.
- Added a compact session timeline to Meet Day Details, color-matched to the Sessions list, showing each session's place across the day.
- Replaced the day-wide "Billable Time" summary with a per-judge billable hours breakdown, since the per-judge daily minimum means that total depends on which judge worked which sessions.
- Sessions can now be reordered by dragging (tap Edit on the Meet Day Details screen).
- Added "Add New Judge" on the Session Details screen to add a judge to the meet and assign them to just that session in one step.
- Judges already busy with an overlapping session are now shown grayed out in the session's judge list instead of only failing after being tapped.

## Version 5.1 (Build 36)

This update focuses on session-based judge assignment, mileage-rate accuracy, and meet-day visibility.

- Removed the `SixSeven` judge level from new selections.
- Updated mileage-rate handling to use effective dates, including the federal rate change to `0.76` starting July 1, 2026.
- Changed session behavior so judges are no longer auto-assigned when:
  - adding a new meet day
  - adding the first session on that day
  - adding later sessions
- Preserved manual session assignments after leaving and reopening a meet.
- Added overlap protection when editing session times so assigned judges cannot be double-booked.
- Added `Add All` and `Remove All` actions on the session details screen.
- Fixed the session details checklist so checkmarks update correctly after bulk assignment changes.
- Added the assigned-judge count to each session in meet day details.
- Fixed the meet overview day cards so the judge icon count reflects judges actually assigned to that day, not the full meet judge roster.

## Notes

- If a session time change would create a conflict, the change is rejected and the app lists the affected judge/session overlaps.
- If `Add All` cannot assign every judge, the app reports only the judges blocked by overlap rules.
