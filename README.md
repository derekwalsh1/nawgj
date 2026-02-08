# NAWGJ Expense Tracker

NAWGJ Expense Tracker is a comprehensive iOS application designed for gymnastics judges and meet organizers to efficiently track, manage, and report all meet-related expenses and fees. The app supports multi-day meets, multiple judges, a wide variety of expense types, and generates detailed PDF reports for both meets and individual judges. It is built for accuracy, flexibility, and ease of use.

---

## Features

### Meet Management
- Create, edit, and delete meets with:
  - Name, location, description, and start date
  - Support for multi-day meets (add, edit, remove days)
  - Assign multiple judges to each meet
  - Track meet-level and per-day details

### Judge Management
- Add, edit, and remove judges
- Assign judges to meets
- Supports USAG and NGA judge levels, each with automatic hourly rates
- Unique judge IDs for data integrity
- Judges can be imported/exported as JSON

### Expense Tracking
- Track expenses at both the meet and judge level
- Supported expense types:
  - Mileage (with federal rate lookup and custom override)
  - Meals
  - Tolls/Bridges
  - Airfare
  - Transportation
  - Parking
  - Lodging (with max daily expense logic)
  - Other (custom notes)
- Add notes, dates, and custom rates to expenses
- Automatic calculation of total and billable hours, with minimums and break handling
- Quarter-hour rounding for billing

### Fee Management
- Automatic fee calculation based on judge level and billable hours
- Manual override of hours and rates per fee
- Exclude specific fees from totals (e.g., for absences)
- Add notes to fees
- Fees are linked to specific meet days for accurate reporting

### Federal Mileage Rate Support
- Automatic lookup of IRS federal mileage rates by year (2016–2025)
- Fallback logic for years outside the table (uses closest available rate)
- Custom mileage rates supported per expense

### Data Import/Export
- Import and export meets and judges as JSON files
- Uses UIDocumentPicker for file selection and sharing
- Supports backup, restore, and data transfer between devices

### PDF Report Generation
- Generate detailed PDF reports for:
  - Entire meets (all judges, all days, all expenses)
  - Individual judges (fees, expenses, per-meet breakdown)
- Reports include:
  - Formatted tables for fees, expenses, and summaries
  - Meet and judge metadata (name, level, location, dates)
  - Federal mileage rate used
  - Custom footers with page numbers, report date, and context
- Share or export PDFs via email, AirDrop, or other iOS sharing options

### User Interface
- Intuitive table views for lists of meets, judges, days, and expenses
- Detail screens for editing and reviewing data
- Custom table view cells for clear, color-coded display
- Dynamic Type and preferred font styles for accessibility
- Color highlights for totals, warnings, and important fields

### Error Handling and Data Integrity
- Safe defaults for all optional fields
- Index guards to prevent crashes on invalid access
- Logging for failed operations (e.g., fee creation)
- Defensive coding for all user input and file operations

### Platform and Technology
- iOS 13 and later (iPhone and iPad supported)
- Built with UIKit, PDFKit, MessageUI, and Foundation
- Data persistence via JSON in app’s documents directory
- No special entitlements or configuration required

---

## User Guide & Workflow

### 1. Adding a Meet
- Tap “Add Meet” and enter the meet’s name, location, description, and start date
- Add one or more meet days, specifying date, start/end time, number of breaks, and break duration
- Assign judges to the meet from the judge list or add new judges

### 2. Managing Judges
- Add new judges with name and level (USAG or NGA)
- Edit judge details or remove judges as needed
- Assign judges to meets; judge fees are calculated automatically based on level and hours

### 3. Tracking Expenses
- For each meet or judge, add expenses by type
- Enter amount, date, notes, and (for mileage) rate or custom rate
- Lodging expenses are capped by a configurable maximum daily amount
- All expenses are included in total and per-judge calculations

### 4. Managing Fees
- Fees are created automatically for each judge and meet day
- Manually override hours or rates for special cases
- Exclude fees from totals if needed (e.g., for absences)
- Add notes to any fee for record-keeping

### 5. Generating and Sharing Reports
- Select a meet or judge and tap “Generate Report”
- Choose to generate a PDF for the entire meet or for an individual judge
- Review the formatted PDF, then share or export via email, AirDrop, or other iOS sharing options

### 6. Importing and Exporting Data
- Use the import/export buttons to save or load meet and judge data as JSON
- Supports backup, restore, and transfer between devices

### 7. Editing and Removing Data
- Edit or remove meets, judges, meet days, expenses, and fees at any time
- All changes are saved automatically

### 8. Customization and Advanced Options
- Override fee rates and hours for special cases
- Exclude fees from totals
- Add notes to any fee or expense
- Custom mileage rates supported

---

## Technical Details

### Data Model
- **Meet:** Holds name, days, judges, start date, description, location, and manages all calculations
- **MeetDay:** Represents a single day of a meet, with date, start/end time, breaks, and unique ID
- **Judge:** Represents a judge, with name, level (USAG/NGA), and associated fees and expenses
- **Fee:** Represents a judge’s fee for a meet day, with hours, rate, notes, and exclusion logic
- **Expense:** Represents an expense (mileage, meals, etc.), with type, amount, notes, date, and custom fields

### Managers
- **MeetListManager:** Singleton for managing the list of meets, loading/saving, and selection
- **JudgeListManager:** Singleton for managing the list of judges, loading/saving, and selection

### PDF Generation
- **MeetPDFCreator/JudgePDFCreator:** Generate HTML and render to PDF using UIPrintPageRenderer
- **MeetUIPrintPageRender/JudgeUIPrintPageRender:** Custom footers, page numbers, and metadata
- **PDFViewController/JudgePDFViewController:** Preview, share, and export PDFs

### Import/Export
- Uses UIDocumentPicker for file selection
- JSON serialization for all data models
- Defensive error handling for file operations

### UI Architecture
- **MVC pattern** throughout
- Table view controllers for all lists and detail screens
- Custom table view cells for meets, judges, and import/export actions
- Color and font styling for clarity and accessibility

---

## How to Build and Run
1. Open `NawgjExpenseTracker.xcodeproj` in Xcode.
2. Build and run on a simulator or device running iOS 13 or later.
3. The app requires no special entitlements or configuration.

---

## License
Copyright © 2018-2025 Derek Walsh. All rights reserved.

---
For questions or contributions, contact the author or open an issue in the repository.
