#!/usr/bin/env python3
import json

# Extract the same judges from the meet data for consistency
judges_data = [
    {"name": "Sarah Mitchell", "level": 5, "fromCity": "Boulder"},
    {"name": "Michael Chen", "level": 5, "fromCity": "Fort Collins"},
    {"name": "Jennifer Rodriguez", "level": 6, "fromCity": "Phoenix"},
    {"name": "David Thompson", "level": 6, "fromCity": "Colorado Springs"},
    {"name": "Amanda Williams", "level": 3, "fromCity": "Littleton"},
    {"name": "Robert Martinez", "level": 3, "fromCity": "Pueblo"},
    {"name": "Lisa Anderson", "level": 1, "fromCity": "Aurora"},
    {"name": "Christopher Lee", "level": 1, "fromCity": "Cheyenne"},
    {"name": "Emily Jackson", "level": 1, "fromCity": "Westminster"},
    {"name": "Daniel White", "level": 1, "fromCity": "Greeley"},
    {"name": "Michelle Davis", "level": 6, "fromCity": "Salt Lake City"},
    {"name": "Kevin Brown", "level": 3, "fromCity": "Lakewood"},
    {"name": "Nicole Taylor", "level": 1, "fromCity": "Arvada"},
    {"name": "Brian Wilson", "level": 5, "fromCity": "Seattle"},
    {"name": "Patricia Moore", "level": 1, "fromCity": "Thornton"},
    {"name": "Steven Garcia", "level": 3, "fromCity": "Grand Junction"},
    {"name": "Karen Miller", "level": 6, "fromCity": "Vail"},
    {"name": "Jason Harris", "level": 1, "fromCity": "Brighton"},
    {"name": "Rebecca Clark", "level": 1, "fromCity": "Longmont"},
    {"name": "Thomas Lewis", "level": 5, "fromCity": "Chicago"},
    {"name": "Angela Robinson", "level": 3, "fromCity": "Centennial"},
    {"name": "Gregory Walker", "level": 1, "fromCity": "Loveland"},
    {"name": "Sandra Young", "level": 6, "fromCity": "Albuquerque"},
    {"name": "Mark King", "level": 1, "fromCity": "Englewood"},
    {"name": "Catherine Scott", "level": 1, "fromCity": "Parker"},
]

# Level descriptions to match what's in the enum
level_descriptions = {
    5: "National",           # National($34/hr)
    6: "Brevet",            # Brevet($37/hr)
    3: "Level 9",           # Level 9($27/hr)
    1: "Levels 6, 7 and 8", # Levels 6-8($21/hr)
    4: "Level 10",          # Level 10($31/hr)
}

# Build the judges list (JudgeInfo objects)
judges = []
for jdata in judges_data:
    judge = {
        "name": jdata["name"],
        "level": jdata["level"]
    }
    judges.append(judge)

# Write to file
with open('SampleJudges.json', 'w') as f:
    json.dump(judges, f, indent=2)

print(f"Generated {len(judges)} judges")
print(f"  National (level 5): {sum(1 for j in judges if j['level'] == 5)}")
print(f"  Brevet (level 6): {sum(1 for j in judges if j['level'] == 6)}")
print(f"  Level 9 (level 3): {sum(1 for j in judges if j['level'] == 3)}")
print(f"  Levels 6-8 (level 1): {sum(1 for j in judges if j['level'] == 1)}")
print(f"\n✓ Judges file created: SampleJudges.json")
