# Sample Meet Data - README

## Overview
This directory contains a comprehensive sample meet for testing and generating screenshots.

## Sample Meet Details

### **Spring Classic Championship 2026**
- **Location:** Denver Convention Center, Denver, CO
- **Dates:** March 20-22, 2026 (3 days)
- **Competition Levels:** Level 6-10, Xcel Gold-Platinum
- **Type:** Regional Championship
- **Mileage Rate:** $0.70/mile (2026 federal rate)

### Meet Schedule

#### Day 1 - March 20, 2026
- Start: 8:00 AM
- End: 6:30 PM
- Total Time: 10.5 hours
- Breaks: 2 (60 minutes total)
- Billable Hours: 9.5 hours

#### Day 2 - March 21, 2026
- Start: 8:00 AM
- End: 7:00 PM
- Total Time: 11 hours
- Breaks: 2 (60 minutes total)
- Billable Hours: 10.0 hours

#### Day 3 - March 22, 2026
- Start: 9:00 AM
- End: 5:00 PM
- Total Time: 8 hours
- Breaks: 1 (45 minutes)
- Billable Hours: 7.25 hours

## Judge Distribution (25 Total)

### By Level:
- **National (4 judges)** - $34/hour - enum value: 5
  - Sarah Mitchell (Meet Referee)
  - Michael Chen
  - Brian Wilson
  - Thomas Lewis

- **Brevet (5 judges)** - $37/hour - enum value: 6
  - Jennifer Rodriguez
  - David Thompson
  - Michelle Davis
  - Karen Miller
  - Sandra Young

- **Level 9 (5 judges)** - $27/hour - enum value: 3
  - Amanda Williams
  - Robert Martinez
  - Kevin Brown
  - Steven Garcia
  - Angela Robinson

- **Levels 6, 7, 8 (11 judges)** - $21/hour - enum value: 1
  - Lisa Anderson
  - Christopher Lee
  - Emily Jackson
  - Daniel White
  - Nicole Taylor
  - Patricia Moore
  - Jason Harris
  - Rebecca Clark
  - Gregory Walker
  - Mark King
  - Catherine Scott

### By Work Pattern:
- **All 3 days:** 17 judges
- **2 days only:** 8 judges
- **1 day only:** 0 judges

### By Travel Method:
- **Driving (local):** 17 judges (various mileage amounts)
- **Flying (out-of-state):** 5 judges (with airfare and transportation)
  - Phoenix, Salt Lake City, Seattle, Chicago, Albuquerque
- **No lodging needed:** 8 judges (local/day judges)

## Expense Breakdown

Each judge has realistic expenses including:
- **Mileage:** Calculated at $0.70/mile (2026 rate)
- **Lodging:** 1-3 nights at varying hotel rates ($115-165/night)
- **Airfare:** $365-545 for out-of-state judges
- **Meals:** $22-42/day based on number of days worked
- **Parking:** $15/day when applicable
- **Transportation:** $55-85 for airport shuttles (flying judges)

## Payment & Administrative Status

The sample includes a realistic mix of:
- **Paid judges:** ~67% (varied by judge ID)
- **Unpaid judges:** ~33%
- **W9 Received:** ~75%
- **Receipts Received:** ~80%

## Meet Referee
**Sarah Mitchell** is designated as the Meet Referee with an additional fee of $200.00.

## Usage

### To Import:
1. Open the app
2. Navigate to Meet List or Judge List
3. Tap "Import"
4. Select `SampleMeet.json` (for complete meet) or `SampleJudges.json` (for judges only)

**Import Judges:**
- File: `SampleJudges.json`
- Contains: 25 judges with names and levels only
- Use this to pre-populate your judge roster before creating meets

**Import Meet:**
- File: `SampleMeet.json`  
- Contains: Complete 3-day meet with 25 judges, all fees, and expenses
- Perfect for testing the full meet workflow

### For Testing:
This sample provides excellent coverage for:
- ✓ All judge levels and pay rates
- ✓ Multiple expense types
- ✓ Various travel scenarios (local, regional, out-of-state)
- ✓ Multi-day scheduling
- ✓ Mix of payment statuses
- ✓ Meet referee handling
- ✓ PDF generation with complex tables
- ✓ Summary calculations and totals
- ✓ Expense tracking across different categories

### For Screenshots:
The variety ensures you can capture:
- Full judge roster with different levels
- Diverse expense reports
- Multi-day scheduling
- Complete meet summaries
- Individual judge invoices with various expense types
- Payment status tracking

## Total Meet Statistics (Approximate)

- **Total Judge Hours:** ~635 billable hours
- **Total Judge Fees:** ~$27,000
- **Total Expenses:** ~$15,000
- **Total Meet Cost:** ~$42,000
- **Average per Judge:** ~$1,680

## Files

- `SampleMeet.json` - The complete sample meet data with 25 judges and full expenses
- `SampleJudges.json` - Just the 25 judges (for importing into judge list)
- `generate_sample.py` - Python script used to generate the meet data
- `generate_judges.py` - Python script used to generate the judges list
- `README.md` - This file

## Regenerating

To regenerate with different data:
```bash
cd NawgjExpenseTracker/TestData

# Generate the complete meet with judges, days, fees, and expenses
python3 generate_sample.py

# Generate just the judges list
python3 generate_judges.py
```

Edit the scripts to modify:
- Judge names and levels
- Expense amounts
- Cities and distances
- Day patterns
- Meet details
