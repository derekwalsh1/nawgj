#!/usr/bin/env python3
"""
Generates test data for App Store screenshots/previews and general manual
testing:

  - TestJudges.json  - a 40-judge roster (name + level) for importing into
                        the Judge List ("Import" on the Judges screen).
  - TestMeetLarge.json  - a 3-day meet with multiple, sometimes-overlapping
                           sessions per day (25 judges).
  - TestMeetMedium.json - a single-day meet with 3 overlapping sessions
                           (12 judges).
  - TestMeetSmall.json  - a single-day, single-session meet (5 judges).

Each meet file is a single `Meet` JSON object (matches the "Import Meet"
file format used by MeetListManager.importMeet(fromFile:)); TestJudges.json
is a JSON array of `{name, level}` objects (matches "Import Judges").

Level enum raw values (see Judge.swift, Judge.Level):
  7 = NGA_Local ($23/hr)         8 = NGA_State ($27/hr)
  12 = Levels 4,5,X1R ($20/hr)   13 = Levels 6,7 ($21/hr)
  14 = Level 8,XR ($24/hr)       15 = Level 9 ($28/hr)
  16 = Level 10 ($32/hr)         17 = N4 ($34/hr)
  18 = N3 ($36/hr)               19 = B2/N2 ($38/hr)
  20 = B1/N1 ($40/hr)
(Only the "selectableCases" - current, non-legacy - levels are used here.)
"""

import json
import math
import uuid as uuidlib
from datetime import datetime, timedelta, timezone

# MARK: - Constants mirroring the Swift model's billing rules

RATES = {
    7: 23.0, 8: 27.0, 9: 31.0, 10: 34.0, 11: 37.0,
    12: 20.0, 13: 21.0, 14: 24.0, 15: 28.0, 16: 32.0,
    17: 34.0, 18: 36.0, 19: 38.0, 20: 40.0,
}

MIN_BILLING_HOURS = 3.0
MAX_BREAK_TIME_HOURS = 2.0
DEFAULT_BREAK_MINS = 30
MILEAGE_RATE_2026 = 0.725  # Meet.FED_MILEAGE_RATES[2026]

# Swift's `Codable` encodes/decodes `Date` (with no custom date strategy, which
# is what this app's models use) as `timeIntervalSinceReferenceDate` - seconds
# since 2001-01-01, NOT the Unix epoch (1970-01-01). Using a raw Unix
# timestamp here would decode ~31 years in the future on the Swift side.
APPLE_REFERENCE_DATE_OFFSET = 978307200  # seconds between 1970-01-01 and 2001-01-01


def to_ts(dt: datetime) -> float:
    return dt.timestamp() - APPLE_REFERENCE_DATE_OFFSET


def total_time_hours(start: datetime, end: datetime) -> float:
    """Mirrors BillableTimeRange.totalTimeInHours() - rounds to nearest
    quarter hour using the same >0.25/<=0.75 and >0.75 breakpoints."""
    hours = (end - start).total_seconds() / 3600
    whole = math.floor(hours)
    remainder = hours - whole
    if 0.25 < remainder <= 0.75:
        whole += 0.5
    elif remainder > 0.75:
        whole += 1
    return float(whole)


def billable_hours(start: datetime, end: datetime, breaks: int, break_mins: int) -> float:
    """Mirrors BillableTimeRange.totalBillableTimeInHours()."""
    total = total_time_hours(start, end)
    break_hours = min((breaks * break_mins) / 60.0, MAX_BREAK_TIME_HOURS)
    return max(MIN_BILLING_HOURS, total - break_hours)


def new_uuid() -> str:
    return str(uuidlib.uuid4())


# MARK: - Judge roster (40 judges)

# (name, level, city, "far" flag for airfare-eligible out-of-state judges)
ROSTER = [
    ("Sarah Mitchell", 17, "Boulder", False),
    ("Michael Chen", 16, "Fort Collins", False),
    ("Jennifer Rodriguez", 18, "Phoenix", True),
    ("David Thompson", 15, "Colorado Springs", False),
    ("Amanda Williams", 14, "Littleton", False),
    ("Robert Martinez", 13, "Pueblo", False),
    ("Lisa Anderson", 12, "Aurora", False),
    ("Christopher Lee", 13, "Cheyenne", False),
    ("Emily Jackson", 12, "Westminster", False),
    ("Daniel White", 14, "Greeley", False),
    ("Michelle Davis", 19, "Salt Lake City", True),
    ("Kevin Brown", 15, "Lakewood", False),
    ("Nicole Taylor", 12, "Arvada", False),
    ("Brian Wilson", 20, "Seattle", True),
    ("Patricia Moore", 13, "Thornton", False),
    ("Steven Garcia", 16, "Grand Junction", False),
    ("Karen Miller", 18, "Vail", False),
    ("Jason Harris", 14, "Brighton", False),
    ("Rebecca Clark", 12, "Longmont", False),
    ("Thomas Lewis", 17, "Chicago", True),
    ("Angela Robinson", 15, "Centennial", False),
    ("Gregory Walker", 13, "Loveland", False),
    ("Sandra Young", 19, "Albuquerque", True),
    ("Mark King", 12, "Englewood", False),
    ("Catherine Scott", 14, "Parker", False),
    ("Brandon Adams", 16, "Highlands Ranch", False),
    ("Melissa Nelson", 12, "Broomfield", False),
    ("Justin Carter", 13, "Golden", False),
    ("Stephanie Mitchell", 15, "Wheat Ridge", False),
    ("Ryan Perez", 14, "Commerce City", False),
    ("Laura Roberts", 17, "Durango", False),
    ("Eric Turner", 12, "Northglenn", False),
    ("Amy Phillips", 13, "Superior", False),
    ("Jonathan Campbell", 18, "Steamboat Springs", False),
    ("Heather Parker", 16, "Louisville", False),
    ("Scott Evans", 12, "Castle Rock", False),
    ("Diane Edwards", 14, "Glenwood Springs", False),
    ("Timothy Collins", 8, "Las Vegas", True),
    ("Andrea Stewart", 13, "Portland", True),
    ("Paul Morris", 7, "Golden", False),
]
assert len(ROSTER) == 40

# Full default expense category list every judge gets (matches the 8
# categories ExpensesListView always shows / Judge.init(name:level:fees:)'s
# default expenses).
EXPENSE_TYPES = {
    "Mileage": 0, "Meals": 1, "Toll": 2, "Airfare": 3,
    "Transportation": 4, "Parking": 5, "Lodging": 6, "Other": 7,
}


def default_expense(type_name: str, date_ts: float) -> dict:
    return {
        "type": EXPENSE_TYPES[type_name],
        "amount": 0.0,
        "notes": "",
        "date": date_ts,
        "mileageRate": MILEAGE_RATE_2026,
        "isCustomMileageRate": False,
        "isPrivateLodgingRequested": False,
        "totalNights": 0,
        "amountPerNight": 0.0,
    }


def build_expenses(anchor_ts: float, *, miles=0, meals=0.0, tolls=0.0,
                    airfare=0.0, transportation=0.0, parking=0.0,
                    nights=0, per_night=0.0, other=0.0) -> list:
    """Builds the full 8-category expense list for a judge, filling in real
    amounts for the categories passed in and zeroing the rest."""
    expenses = {name: default_expense(name, anchor_ts) for name in EXPENSE_TYPES}

    if miles > 0:
        expenses["Mileage"]["amount"] = float(miles)
        expenses["Mileage"]["notes"] = "Round trip mileage"
    if meals > 0:
        expenses["Meals"]["amount"] = round(meals, 2)
        expenses["Meals"]["notes"] = "Meals/per diem"
    if tolls > 0:
        expenses["Toll"]["amount"] = round(tolls, 2)
        expenses["Toll"]["notes"] = "Tolls"
    if airfare > 0:
        expenses["Airfare"]["amount"] = round(airfare, 2)
        expenses["Airfare"]["notes"] = "Round trip airfare"
    if transportation > 0:
        expenses["Transportation"]["amount"] = round(transportation, 2)
        expenses["Transportation"]["notes"] = "Airport shuttle / rental car"
    if parking > 0:
        expenses["Parking"]["amount"] = round(parking, 2)
        expenses["Parking"]["notes"] = "Parking"
    if nights > 0:
        expenses["Lodging"]["totalNights"] = nights
        expenses["Lodging"]["amountPerNight"] = round(per_night, 2)
        expenses["Lodging"]["notes"] = "Hotel accommodation"
    if other > 0:
        expenses["Other"]["amount"] = round(other, 2)
        expenses["Other"]["notes"] = "Miscellaneous"

    # Preserve the canonical category order.
    return [expenses[name] for name in EXPENSE_TYPES]


def build_day(meet_date: datetime, sessions: list) -> dict:
    """sessions: list of (name, start, end, breaks, break_mins) tuples."""
    return {
        "meetDate": to_ts(meet_date),
        "uuid": new_uuid(),
        "sessions": [
            {
                "uuid": new_uuid(),
                "name": name,
                "startTime": to_ts(start),
                "endTime": to_ts(end),
                "breaks": breaks,
                "breakTimeInMins": break_mins,
            }
            for (name, start, end, breaks, break_mins) in sessions
        ],
    }


def build_judge(name, level, *, notes="", meet_referee=False, meet_referee_fee=0.0,
                paid=True, w9=True, receipts=True, fees=None, expenses=None) -> dict:
    judge = {
        "name": name,
        "level": level,
        "notes": notes,
        "paid": paid,
        "meetReferee": meet_referee,
        "w9Received": w9,
        "receiptsReceived": receipts,
        "fees": fees or [],
        "expenses": expenses or [],
    }
    if meet_referee:
        judge["meetRefereeFee"] = meet_referee_fee
    return judge


def build_fee(day: dict, session: dict, *, hours=None, exclude=False, notes="") -> dict:
    return {
        "date": day["meetDate"],
        "hours": 0.0 if exclude else hours,
        "rate": 0.0,  # filled in by caller (needs judge level)
        "rateOverridden": False,
        "hoursOverridden": False,
        "exclude": exclude,
        "notes": notes,
        "meetDayUUID": day["uuid"],
        "sessionUUID": session["uuid"],
    }


def fees_for_all_sessions(days: list, level: int, *, working: dict) -> list:
    """Builds one Fee per session across every day of the meet. `working`
    maps day index -> session index the judge actually works that day (or
    None if the judge doesn't work that day at all). Every other session
    gets an excluded (zero-hour) fee so the app's own auto-fill logic never
    has to synthesize one (which would default to non-excluded/full hours
    and incorrectly bill the judge for sessions they didn't work)."""
    rate = RATES[level]
    fees = []
    for day_index, day in enumerate(days):
        worked_session_index = working.get(day_index)
        for session_index, session in enumerate(day["sessions"]):
            if session_index == worked_session_index:
                hrs = billable_hours(
                    datetime.fromtimestamp(session["startTime"], tz=timezone.utc),
                    datetime.fromtimestamp(session["endTime"], tz=timezone.utc),
                    session["breaks"], session["breakTimeInMins"],
                )
                fee = build_fee(day, session, hours=hrs, exclude=False, notes=session["name"])
            else:
                fee = build_fee(day, session, hours=0.0, exclude=True, notes="Not worked")
            fee["rate"] = rate
            fees.append(fee)
    return fees


# MARK: - Large meet: 3 days, multiple (overlapping) sessions per day

def build_large_meet() -> dict:
    # Deliberately naive (no tzinfo): `to_ts()` uses `dt.timestamp()`, which
    # interprets naive datetimes as the *local* system time. This keeps the
    # session hours below (8am-4:30pm, etc.) displaying as the same local
    # wall-clock time on any device that shares the host machine's timezone
    # (the simulator's default), instead of drifting by the UTC offset.
    d1 = datetime(2026, 10, 9, 0, 0)
    d2 = datetime(2026, 10, 10, 0, 0)
    d3 = datetime(2026, 10, 11, 0, 0)

    day1 = build_day(d1, [
        ("Compulsory Session", d1.replace(hour=8), d1.replace(hour=13), 2, 30),
        ("Xcel Session", d1.replace(hour=8, minute=30), d1.replace(hour=13, minute=30), 2, 30),
    ])
    day2 = build_day(d2, [
        ("Session A", d2.replace(hour=8), d2.replace(hour=12, minute=30), 2, 30),
        ("Session B", d2.replace(hour=8), d2.replace(hour=13), 2, 30),
        ("Session C", d2.replace(hour=9), d2.replace(hour=14), 2, 30),
    ])
    day3 = build_day(d3, [
        ("AM Session", d3.replace(hour=8), d3.replace(hour=12), 1, 30),
        ("PM Session", d3.replace(hour=12, minute=30), d3.replace(hour=16, minute=30), 1, 30),
    ])
    days = [day1, day2, day3]

    roster = ROSTER[0:25]

    # Deterministic working-day/session pattern: cycle through a handful of
    # attendance patterns so the meet has a realistic mix of 1/2/3-day
    # judges, each assigned to exactly one session on the day(s) they work.
    patterns = [
        {0: 0, 1: 0, 2: 0}, {0: 1, 1: 1, 2: 1}, {0: 0, 1: 2, 2: 1},
        {0: 1, 1: 0, 2: 0}, {0: 0, 1: 1},        {1: 2, 2: 0},
        {0: 1},              {1: 0, 2: 1},        {0: 0, 1: 1, 2: 0},
        {0: 1, 1: 2, 2: 1},
    ]

    judges = []
    for idx, (name, level, city, far) in enumerate(roster):
        working = patterns[idx % len(patterns)]
        num_days_worked = len(working)
        is_referee = idx == 0

        fees = fees_for_all_sessions(days, level, working=working)

        first_worked_day = min(working.keys())
        anchor_ts = days[first_worked_day]["meetDate"]

        if far:
            expenses = build_expenses(
                anchor_ts,
                airfare=365.0 + idx * 12.5,
                transportation=55.0 + idx * 2.5,
                meals=24.0 * num_days_worked,
                nights=max(num_days_worked, 1),
                per_night=125.0 + idx * 1.5,
            )
        else:
            miles = 30 + (idx * 11) % 220
            needs_lodging = num_days_worked >= 2 and miles > 100
            expenses = build_expenses(
                anchor_ts,
                miles=miles,
                meals=24.0 * num_days_worked,
                parking=15.0 * num_days_worked if miles > 60 else 0.0,
                nights=num_days_worked if needs_lodging else 0,
                per_night=129.0 + idx * 1.25 if needs_lodging else 0.0,
            )

        judges.append(build_judge(
            name, level,
            notes=f"Judge from {city}",
            meet_referee=is_referee,
            meet_referee_fee=200.0 if is_referee else 0.0,
            paid=idx % 3 != 0,
            w9=idx % 4 != 0,
            receipts=idx % 5 != 0,
            fees=fees,
            expenses=expenses,
        ))

    return {
        "name": "2026 State Championships",
        "startDate": to_ts(d1),
        "location": "Colorado Convention Center, Denver, CO",
        "meetDescription": "Levels 6-10, Xcel Gold-Platinum - State Championship",
        "days": days,
        "judges": judges,
    }


# MARK: - Medium meet: single day, 3 overlapping sessions

def build_medium_meet() -> dict:
    d = datetime(2026, 9, 12, 0, 0)
    day = build_day(d, [
        ("Session A", d.replace(hour=8), d.replace(hour=13), 1, 30),
        ("Session B", d.replace(hour=8, minute=30), d.replace(hour=13, minute=30), 1, 30),
        ("Session C", d.replace(hour=9), d.replace(hour=14), 1, 30),
    ])
    days = [day]

    roster = ROSTER[10:22]  # 12 judges (some overlap with the large meet's roster)

    judges = []
    for idx, (name, level, city, far) in enumerate(roster):
        session_index = idx % 3
        working = {0: session_index}
        fees = fees_for_all_sessions(days, level, working=working)

        miles = 20 + (idx * 9) % 90
        expenses = build_expenses(
            day["meetDate"],
            miles=miles,
            meals=22.0,
            parking=10.0 if miles > 40 else 0.0,
        )

        judges.append(build_judge(
            name, level,
            notes=f"Judge from {city}",
            paid=idx % 3 != 0,
            w9=idx % 3 != 0,
            receipts=idx % 4 != 0,
            fees=fees,
            expenses=expenses,
        ))

    return {
        "name": "2026 Fall Sectional Invitational",
        "startDate": to_ts(d),
        "location": "Boulder Rec Center, Boulder, CO",
        "meetDescription": "Levels 4-8 - Sectional Meet",
        "days": days,
        "judges": judges,
    }


# MARK: - Small meet: single day, single session

def build_small_meet() -> dict:
    d = datetime(2026, 8, 22, 0, 0)
    day = build_day(d, [
        ("Session 1", d.replace(hour=8), d.replace(hour=12), 1, 15),
    ])
    days = [day]

    roster = ROSTER[30:35]  # 5 judges

    judges = []
    for idx, (name, level, city, far) in enumerate(roster):
        working = {0: 0}
        fees = fees_for_all_sessions(days, level, working=working)

        miles = 15 + (idx * 7) % 40
        expenses = build_expenses(
            day["meetDate"],
            miles=miles,
            meals=18.0,
        )

        judges.append(build_judge(
            name, level,
            notes=f"Judge from {city}",
            paid=idx != 4,
            w9=True,
            receipts=idx != 3,
            fees=fees,
            expenses=expenses,
        ))

    return {
        "name": "Local Dual Meet",
        "startDate": to_ts(d),
        "location": "Aurora Gymnastics Center, Aurora, CO",
        "meetDescription": "Levels 4-6 - Local Dual Meet",
        "days": days,
        "judges": judges,
    }


def write_json(obj, filename):
    with open(filename, "w") as f:
        json.dump(obj, f, indent=2)
    print(f"Wrote {filename}")


def main():
    # TestJudges.json - roster only (name + level), for "Import Judges".
    test_judges = [{"name": name, "level": level} for (name, level, _, _) in ROSTER]
    write_json(test_judges, "TestJudges.json")

    large = build_large_meet()
    medium = build_medium_meet()
    small = build_small_meet()

    write_json(large, "TestMeetLarge.json")
    write_json(medium, "TestMeetMedium.json")
    write_json(small, "TestMeetSmall.json")

    for label, meet in (("Large", large), ("Medium", medium), ("Small", small)):
        total_sessions = sum(len(d["sessions"]) for d in meet["days"])
        print(f"{label} meet: {len(meet['days'])} day(s), {total_sessions} session(s), "
              f"{len(meet['judges'])} judge(s)")


if __name__ == "__main__":
    main()
