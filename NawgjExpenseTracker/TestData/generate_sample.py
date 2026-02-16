#!/usr/bin/env python3
import json
from datetime import datetime

# Judge data with varying levels and patterns
judges_data = [
    {"name": "Sarah Mitchell", "level": "National", "meetRef": True, "days": [1,2,3], "fromCity": "Boulder", "miles": 245, "lodging": 2, "airfare": 0},
    {"name": "Michael Chen", "level": "National", "meetRef": False, "days": [1,2,3], "fromCity": "Fort Collins", "miles": 185, "lodging": 2, "airfare": 0},
    {"name": "Jennifer Rodriguez", "level": "Brevet", "meetRef": False, "days": [1,2,3], "fromCity": "Phoenix", "miles": 0, "lodging": 3, "airfare": 425},
    {"name": "David Thompson", "level": "Brevet", "meetRef": False, "days": [1,2], "fromCity": "Colorado Springs", "miles": 120, "lodging": 0, "airfare": 0},
    {"name": "Amanda Williams", "level": "Rating 9", "meetRef": False, "days": [1,2,3], "fromCity": "Littleton", "miles": 95, "lodging": 2, "airfare": 0},
    {"name": "Robert Martinez", "level": "Rating 9", "meetRef": False, "days": [2,3], "fromCity": "Pueblo", "miles": 156, "lodging": 1, "airfare": 0},
    {"name": "Lisa Anderson", "level": "Rating 8", "meetRef": False, "days": [1,2,3], "fromCity": "Aurora", "miles": 68, "lodging": 0, "airfare": 0},
    {"name": "Christopher Lee", "level": "Rating 8", "meetRef": False, "days": [1,2], "fromCity": "Cheyenne", "miles": 210, "lodging": 1, "airfare": 0},
    {"name": "Emily Jackson", "level": "Rating 7", "meetRef": False, "days": [1,2,3], "fromCity": "Westminster", "miles": 42, "lodging": 0, "airfare": 0},
    {"name": "Daniel White", "level": "Rating 7", "meetRef": False, "days": [2,3], "fromCity": "Greeley", "miles": 138, "lodging": 0, "airfare": 0},
    {"name": "Michelle Davis", "level": "Brevet", "meetRef": False, "days": [1,2,3], "fromCity": "Salt Lake City", "miles": 0, "lodging": 3, "airfare": 385},
    {"name": "Kevin Brown", "level": "Rating 9", "meetRef": False, "days": [1,3], "fromCity": "Lakewood", "miles": 88, "lodging": 0, "airfare": 0},
    {"name": "Nicole Taylor", "level": "Rating 8", "meetRef": False, "days": [1,2,3], "fromCity": "Arvada", "miles": 124, "lodging": 2, "airfare": 0},
    {"name": "Brian Wilson", "level": "National", "meetRef": False, "days": [1,2,3], "fromCity": "Seattle", "miles": 0, "lodging": 3, "airfare": 495},
    {"name": "Patricia Moore", "level": "Rating 7", "meetRef": False, "days": [1,2], "fromCity": "Thornton", "miles": 54, "lodging": 0, "airfare": 0},
    {"name": "Steven Garcia", "level": "Rating 9", "meetRef": False, "days": [2,3], "fromCity": "Grand Junction", "miles": 168, "lodging": 1, "airfare": 0},
    {"name": "Karen Miller", "level": "Brevet", "meetRef": False, "days": [1,2,3], "fromCity": "Vail", "miles": 196, "lodging": 2, "airfare": 0},
    {"name": "Jason Harris", "level": "Rating 8", "meetRef": False, "days": [1,2], "fromCity": "Brighton", "miles": 76, "lodging": 0, "airfare": 0},
    {"name": "Rebecca Clark", "level": "Rating 7", "meetRef": False, "days": [2,3], "fromCity": "Longmont", "miles": 102, "lodging": 0, "airfare": 0},
    {"name": "Thomas Lewis", "level": "National", "meetRef": False, "days": [1,2,3], "fromCity": "Chicago", "miles": 0, "lodging": 3, "airfare": 545},
    {"name": "Angela Robinson", "level": "Rating 9", "meetRef": False, "days": [1,2,3], "fromCity": "Centennial", "miles": 112, "lodging": 2, "airfare": 0},
    {"name": "Gregory Walker", "level": "Rating 8", "meetRef": False, "days": [2,3], "fromCity": "Loveland", "miles": 144, "lodging": 1, "airfare": 0},
    {"name": "Sandra Young", "level": "Brevet", "meetRef": False, "days": [1,2], "fromCity": "Albuquerque", "miles": 0, "lodging": 2, "airfare": 365},
    {"name": "Mark King", "level": "Rating 7", "meetRef": False, "days": [1,3], "fromCity": "Englewood", "miles": 58, "lodging": 0, "airfare": 0},
    {"name": "Catherine Scott", "level": "Rating 8", "meetRef": False, "days": [1,2,3], "fromCity": "Parker", "miles": 92, "lodging": 2, "airfare": 0},
]

# Rate mapping
rates = {
    "National": 60.0,
    "Brevet": 50.0,
    "Rating 9": 40.0,
    "Rating 8": 35.0,
    "Rating 7": 30.0
}

# Day hours
day_hours = {1: 9.5, 2: 10.0, 3: 7.25}

judges = []
for idx, jdata in enumerate(judges_data, 1):
    judge = {
        "id": f"judge-{idx:03d}",
        "name": jdata["name"],
        "level": jdata["level"],
        "meetReferee": jdata["meetRef"],
        "paid": idx % 3 != 0,  # Mix of paid/unpaid
        "w9Received": idx % 4 != 0,
        "receiptsReceived": idx % 5 != 0,
        "notes": f"Specialty judge - {jdata['fromCity']}",
        "fees": [],
        "expenses": []
    }
    
    if jdata["meetRef"]:
        judge["meetRefereeFee"] = 200.0
    
    # Add fees for each day
    rate = rates[jdata["level"]]
    for day in jdata["days"]:
        date_str = f"2026-03-{19+day}T10:00:00Z"
        judge["fees"].append({
            "date": date_str,
            "hours": day_hours[day],
            "rate": rate,
            "exclude": False,
            "notes": f"Day {day}"
        })
    
    # Add expenses
    first_day_date = f"2026-03-{19+jdata['days'][0]}T10:00:00Z"
    
    if jdata["miles"] > 0:
        judge["expenses"].append({
            "type": "Mileage",
            "amount": float(jdata["miles"]),
            "mileageRate": 0.70,
            "date": first_day_date,
            "notes": f"Round trip from {jdata['fromCity']}"
        })
    
    if jdata["airfare"] > 0:
        judge["expenses"].append({
            "type": "Airfare",
            "amount": float(jdata["airfare"]),
            "date": "2026-03-19T10:00:00Z",
            "notes": f"Round trip from {jdata['fromCity']}"
        })
        judge["expenses"].append({
            "type": "Transportation",
            "amount": 55.0 + (idx * 2.5),
            "date": first_day_date,
            "notes": "Airport shuttle and local transport"
        })
    
    if jdata["lodging"] > 0:
        judge["expenses"].append({
            "type": "Lodging",
            "totalNights": jdata["lodging"],
            "amountPerNight": 115.0 + (idx * 1.5),
            "date": first_day_date,
            "notes": "Hotel accommodation"
        })
    
    # Everyone gets meals
    meal_days = len(jdata["days"])
    judge["expenses"].append({
        "type": "Meals",
        "amount": 22.0 * meal_days + (idx * 1.2),
        "date": first_day_date,
        "notes": f"{meal_days} day(s) meals"
    })
    
    # Some get parking
    if jdata["miles"] > 0 and jdata["lodging"] > 0:
        judge["expenses"].append({
            "type": "Parking",
            "amount": 15.0 * len(jdata["days"]),
            "date": first_day_date,
            "notes": f"{len(jdata['days'])} day(s) parking"
        })
    
    judges.append(judge)

# Create complete meet structure
meet = {
    "name": "Spring Classic Championship 2026",
    "startDate": "2026-03-20T10:00:00Z",
    "location": "Denver Convention Center, Denver, CO",
    "meetDescription": "Level 6-10, Xcel Gold-Platinum - Regional Championship",
    "mileageRate": 0.70,
    "days": [
        {
            "id": "day1-uuid-2026-03-20",
            "meetDate": "2026-03-20T10:00:00Z",
            "startTime": "2026-03-20T08:00:00Z",
            "endTime": "2026-03-20T18:30:00Z",
            "breaks": 2,
            "breakTime": 60
        },
        {
            "id": "day2-uuid-2026-03-21",
            "meetDate": "2026-03-21T10:00:00Z",
            "startTime": "2026-03-21T08:00:00Z",
            "endTime": "2026-03-21T19:00:00Z",
            "breaks": 2,
            "breakTime": 60
        },
        {
            "id": "day3-uuid-2026-03-22",
            "meetDate": "2026-03-22T10:00:00Z",
            "startTime": "2026-03-22T09:00:00Z",
            "endTime": "2026-03-22T17:00:00Z",
            "breaks": 1,
            "breakTime": 45
        }
    ],
    "judges": judges
}

# Write to file
with open('SampleMeet.json', 'w') as f:
    json.dump(meet, f, indent=2)

print(f"Generated sample meet with {len(judges)} judges")
print(f"Total National judges: {sum(1 for j in judges if j['level'] == 'National')}")
print(f"Total Brevet judges: {sum(1 for j in judges if j['level'] == 'Brevet')}")
print(f"Total Rating 9 judges: {sum(1 for j in judges if j['level'] == 'Rating 9')}")
print(f"Total Rating 8 judges: {sum(1 for j in judges if j['level'] == 'Rating 8')}")
print(f"Total Rating 7 judges: {sum(1 for j in judges if j['level'] == 'Rating 7')}")
