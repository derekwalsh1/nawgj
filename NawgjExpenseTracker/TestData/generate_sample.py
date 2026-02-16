#!/usr/bin/env python3
import json
from datetime import datetime

# Judge data with varying levels and patterns
# Level enum mapping:
# 0=Levels4-5($19), 1=Levels6-8($21), 2=Levels4-8($23), 3=Level9($27), 4=Level10($31),
# 5=National($34), 6=Brevet($37), 7-11=NGA levels
judges_data = [
    {"name": "Sarah Mitchell", "level": 5, "meetRef": True, "days": [1,2,3], "fromCity": "Boulder", "miles": 245, "lodging": 2, "airfare": 0},
    {"name": "Michael Chen", "level": 5, "meetRef": False, "days": [1,2,3], "fromCity": "Fort Collins", "miles": 185, "lodging": 2, "airfare": 0},
    {"name": "Jennifer Rodriguez", "level": 6, "meetRef": False, "days": [1,2,3], "fromCity": "Phoenix", "miles": 0, "lodging": 3, "airfare": 425},
    {"name": "David Thompson", "level": 6, "meetRef": False, "days": [1,2], "fromCity": "Colorado Springs", "miles": 120, "lodging": 0, "airfare": 0},
    {"name": "Amanda Williams", "level": 3, "meetRef": False, "days": [1,2,3], "fromCity": "Littleton", "miles": 95, "lodging": 2, "airfare": 0},
    {"name": "Robert Martinez", "level": 3, "meetRef": False, "days": [2,3], "fromCity": "Pueblo", "miles": 156, "lodging": 1, "airfare": 0},
    {"name": "Lisa Anderson", "level": 1, "meetRef": False, "days": [1,2,3], "fromCity": "Aurora", "miles": 68, "lodging": 0, "airfare": 0},
    {"name": "Christopher Lee", "level": 1, "meetRef": False, "days": [1,2], "fromCity": "Cheyenne", "miles": 210, "lodging": 1, "airfare": 0},
    {"name": "Emily Jackson", "level": 1, "meetRef": False, "days": [1,2,3], "fromCity": "Westminster", "miles": 42, "lodging": 0, "airfare": 0},
    {"name": "Daniel White", "level": 1, "meetRef": False, "days": [2,3], "fromCity": "Greeley", "miles": 138, "lodging": 0, "airfare": 0},
    {"name": "Michelle Davis", "level": 6, "meetRef": False, "days": [1,2,3], "fromCity": "Salt Lake City", "miles": 0, "lodging": 3, "airfare": 385},
    {"name": "Kevin Brown", "level": 3, "meetRef": False, "days": [1,3], "fromCity": "Lakewood", "miles": 88, "lodging": 0, "airfare": 0},
    {"name": "Nicole Taylor", "level": 1, "meetRef": False, "days": [1,2,3], "fromCity": "Arvada", "miles": 124, "lodging": 2, "airfare": 0},
    {"name": "Brian Wilson", "level": 5, "meetRef": False, "days": [1,2,3], "fromCity": "Seattle", "miles": 0, "lodging": 3, "airfare": 495},
    {"name": "Patricia Moore", "level": 1, "meetRef": False, "days": [1,2], "fromCity": "Thornton", "miles": 54, "lodging": 0, "airfare": 0},
    {"name": "Steven Garcia", "level": 3, "meetRef": False, "days": [2,3], "fromCity": "Grand Junction", "miles": 168, "lodging": 1, "airfare": 0},
    {"name": "Karen Miller", "level": 6, "meetRef": False, "days": [1,2,3], "fromCity": "Vail", "miles": 196, "lodging": 2, "airfare": 0},
    {"name": "Jason Harris", "level": 1, "meetRef": False, "days": [1,2], "fromCity": "Brighton", "miles": 76, "lodging": 0, "airfare": 0},
    {"name": "Rebecca Clark", "level": 1, "meetRef": False, "days": [2,3], "fromCity": "Longmont", "miles": 102, "lodging": 0, "airfare": 0},
    {"name": "Thomas Lewis", "level": 5, "meetRef": False, "days": [1,2,3], "fromCity": "Chicago", "miles": 0, "lodging": 3, "airfare": 545},
    {"name": "Angela Robinson", "level": 3, "meetRef": False, "days": [1,2,3], "fromCity": "Centennial", "miles": 112, "lodging": 2, "airfare": 0},
    {"name": "Gregory Walker", "level": 1, "meetRef": False, "days": [2,3], "fromCity": "Loveland", "miles": 144, "lodging": 1, "airfare": 0},
    {"name": "Sandra Young", "level": 6, "meetRef": False, "days": [1,2], "fromCity": "Albuquerque", "miles": 0, "lodging": 2, "airfare": 365},
    {"name": "Mark King", "level": 1, "meetRef": False, "days": [1,3], "fromCity": "Englewood", "miles": 58, "lodging": 0, "airfare": 0},
    {"name": "Catherine Scott", "level": 1, "meetRef": False, "days": [1,2,3], "fromCity": "Parker", "miles": 92, "lodging": 2, "airfare": 0},
]

# Rate mapping (now using actual enum rates from Judge.swift)
rates = {
    5: 34.0,  # National
    6: 37.0,  # Brevet
    3: 27.0,  # Level 9
    1: 21.0,  # Levels 6, 7, 8
    4: 31.0,  # Level 10
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
        day_id = f"day{day}-uuid-2026-03-{19+day}"
        judge["fees"].append({
            "date": date_str,
            "hours": day_hours[day],
            "rate": rate,
            "rateOverridden": False,
            "hoursOverridden": False,
            "exclude": False,
            "notes": f"Day {day}",
            "meetDayUUID": day_id
        })
    
    # Add expenses
    first_day_date = f"2026-03-{19+jdata['days'][0]}T10:00:00Z"
    
    if jdata["miles"] > 0:
        judge["expenses"].append({
            "type": 0,  # Mileage enum value
            "amount": float(jdata["miles"]),
            "mileageRate": 0.70,
            "isCustomMileageRate": False,
            "date": first_day_date,
            "notes": f"Round trip from {jdata['fromCity']}",
            "isPrivateLodgingRequested": False,
            "totalNights": 0,
            "amountPerNight": 0.0
        })
    
    if jdata["airfare"] > 0:
        judge["expenses"].append({
            "type": 3,  # Airfare enum value
            "amount": float(jdata["airfare"]),
            "mileageRate": 0.0,
            "isCustomMileageRate": False,
            "date": "2026-03-19T10:00:00Z",
            "notes": f"Round trip from {jdata['fromCity']}",
            "isPrivateLodgingRequested": False,
            "totalNights": 0,
            "amountPerNight": 0.0
        })
        judge["expenses"].append({
            "type": 4,  # Transportation enum value
            "amount": 55.0 + (idx * 2.5),
            "mileageRate": 0.0,
            "isCustomMileageRate": False,
            "date": first_day_date,
            "notes": "Airport shuttle and local transport",
            "isPrivateLodgingRequested": False,
            "totalNights": 0,
            "amountPerNight": 0.0
        })
    
    if jdata["lodging"] > 0:
        room_rate = 115.0 + (idx * 1.5)
        judge["expenses"].append({
            "type": 6,  # Lodging enum value
            "amount": room_rate * jdata["lodging"],
            "mileageRate": 0.0,
            "isCustomMileageRate": False,
            "totalNights": jdata["lodging"],
            "amountPerNight": room_rate,
            "date": first_day_date,
            "notes": "Hotel accommodation",
            "isPrivateLodgingRequested": False
        })
    
    # Everyone gets meals
    meal_days = len(jdata["days"])
    judge["expenses"].append({
        "type": 1,  # Meals enum value
        "amount": 22.0 * meal_days + (idx * 1.2),
        "mileageRate": 0.0,
        "isCustomMileageRate": False,
        "date": first_day_date,
        "notes": f"{meal_days} day(s) meals",
        "isPrivateLodgingRequested": False,
        "totalNights": 0,
        "amountPerNight": 0.0
    })
    
    # Some get parking
    if jdata["miles"] > 0 and jdata["lodging"] > 0:
        judge["expenses"].append({
            "type": 5,  # Parking enum value
            "amount": 15.0 * len(jdata["days"]),
            "mileageRate": 0.0,
            "isCustomMileageRate": False,
            "date": first_day_date,
            "notes": f"{len(jdata['days'])} day(s) parking",
            "isPrivateLodgingRequested": False,
            "totalNights": 0,
            "amountPerNight": 0.0
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
print(f"Total National judges (level 5): {sum(1 for j in judges if j['level'] == 5)}")
print(f"Total Brevet judges (level 6): {sum(1 for j in judges if j['level'] == 6)}")
print(f"Total Level 9 judges (level 3): {sum(1 for j in judges if j['level'] == 3)}")
print(f"Total Levels 6-8 judges (level 1): {sum(1 for j in judges if j['level'] == 1)}")
print(f"Total Level 10 judges (level 4): {sum(1 for j in judges if j['level'] == 4)}")
