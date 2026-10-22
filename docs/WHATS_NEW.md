# What's New

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
