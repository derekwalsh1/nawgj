# Repository instructions for coding agents

## Repository overview
- This repository is a Swift/UIKit iOS app for gymnastics meet expense tracking.
- Keep changes focused on the app target under `NawgjExpenseTracker/`.

## Working expectations
1. Read the relevant model, manager, and view controller together before changing behavior.
2. Preserve the existing MVC structure and storyboard-driven UIKit patterns.
3. Avoid breaking JSON persistence, import/export flows, or PDF generation.
4. Prefer small, targeted changes over broad refactors.
5. If a change affects data models, update any related screens and export/import logic.

## Style and safety
- Use Swift idioms consistent with the existing codebase.
- Avoid force unwraps and unsafe array/index access; use guards where appropriate.
- Keep existing naming conventions and public API shape unless a rename is clearly required.
- Prefer existing helpers and singleton managers instead of introducing new infrastructure.

## Verification
- If possible, verify changes with an Xcode build for the `NawgjExpenseTracker` target.
- If verification is blocked by environment limitations, say so explicitly.
