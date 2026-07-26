//
//  Meet.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/22/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

/// Represents a competition meet, its days, and the judges that worked the meet.
///
/// The `Meet` model holds meet-level configuration and convenience
/// calculations such as total hours, total costs, and mileage rate lookup.
/// It is `Codable` so it can be serialized/deserialized for persistence.
class Meet: Codable {
    
    /// Federal mileage rates keyed by year. Used to determine mileage reimbursement.
    static let FED_MILEAGE_RATES: [Int: Float] = [
        2016 : 0.54,
        2017 : 0.535,
        2018 : 0.545,
        2019 : 0.58,
        2020 : 0.575,
        2021 : 0.56,
        2022 : 0.625,
        2023 : 0.655,
        2024 : 0.67,
        2025 : 0.70,
        2026 : 0.725
    ]
    
    /// Maximum daily expense considered expensible for a single-room request.
    /// Stored as `Float` to match other monetary calculations in the model.
    static let SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS: Float = 107.0
    
    /// Returns the mileage rate for a given date using the table above.
    /// If an exact year match isn't found this function returns the most
    /// recent rate for a year <= the requested year. If there is no earlier
    /// rate (requested year is before our table), the earliest available rate
    /// is returned.
    static func getMileageRate(forDate: Date) -> Float {
        let yearComponent = Calendar.current.component(.year, from: forDate)

        // Exact match
        if let rate = Meet.FED_MILEAGE_RATES[yearComponent] {
            return rate
        }

        // Pick the largest year <= requested year
        let candidates = Meet.FED_MILEAGE_RATES.filter { $0.key <= yearComponent }
        if let best = candidates.max(by: { $0.key < $1.key }) {
            return best.value
        }

        // If none are <= requested year, fall back to the earliest available rate
        return Meet.FED_MILEAGE_RATES.min(by: { $0.key < $1.key })?.value ?? 0.725
    }
    
    // MARK: Properties
    /// The meet's display name. Must be non-empty.
    var name: String
    /// The specific meet days; 1 or more days expected.
    var days: [MeetDay]
    /// The Judges that worked at the meet.
    var judges: [Judge]
    /// The first day of the meet.
    var startDate: Date
    /// The levels competing at this meet or a short description. Never nil.
    var meetDescription: String
    /// The location of the meet. Never nil.
    var location: String
        
    // MARK: Initialization
    /// Designated initializer. `name` must be non-empty; `meetDescription`
    /// and `location` default to a single space if `nil` is provided to avoid
    /// storing empty optionals.
    init?(name: String, days: [MeetDay], judges: [Judge], startDate: Date, meetDescription: String?, location: String?) {
        // Initialization should fail if there is an empty name
        guard !name.isEmpty else {
            return nil
        }

        // Provide safe defaults rather than force-unwrapping later.
        let desc = meetDescription ?? " "
        let loc = location ?? " "
        
        // Initialize stored properties.
        self.name = name
        self.days = days
        self.judges = judges
        self.startDate = startDate
        self.meetDescription = desc
        self.location = loc
    }
    
    /// Convenience initializer that creates an empty meet with a name and start date.
    required convenience init?(name: String, startDate: Date) {
        self.init(name: name, days: [MeetDay](), judges: [Judge](), startDate: startDate, meetDescription: " ", location: " ")
    }
    
    /// Mileage rate for this meet's start date.
    func getMileageRate() -> Float{
        return Meet.getMileageRate(forDate: startDate)
    }
    
    // MARK: Meet management and interrogation
    /// Total cost (fees + expenses) of all judges at this meet.
    func totalCostOfMeet() -> Float {
        var totalCost: Float = 0.0
        for judge in self.judges {
            totalCost += judge.totalCost()
        }
        return totalCost
    }

    /// Total hours across all meet days.
    func totalMeetHours() -> Float {
        var totalHours: Float = 0.0
        for day in self.days {
            totalHours += day.totalTimeInHours()
        }
        return totalHours
    }
    
    /// Total billable hours across all meet days.
    func billableMeetHours() -> Float {
        var totalHours: Float = 0.0
        for day in self.days {
            totalHours += day.totalBillableTimeInHours()
        }
        return totalHours
    }
    
    /// Add a meet day and append corresponding fees to each judge. Fee
    /// creation is failable; failures are logged and skipped rather than
    /// force-unwrapping, avoiding runtime crashes.
    func addMeetDay(day: MeetDay) {
        self.days.append(day)
        // add fees to judges for this day
        for judge in self.judges {
            if let fee = Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID()) {
                judge.fees.append(fee)
            } else {
                os_log("Failed to create Fee for judge %{public}@ on date %{public}@", log: OSLog.default, type: .error, judge.name, String(describing: day.meetDate))
            }
        }
    }
    
    /// Add a judge to the meet and append fees for existing meet days.
    func addJudge(judge: Judge){
        for day in self.days {
            if let fee = Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID()) {
                judge.fees.append(fee)
            } else {
                os_log("Failed to create Fee for judge %{public}@ when adding to meet", log: OSLog.default, type: .error, judge.name)
            }
        }
        self.judges.append(judge)
    }
    
    /// Called when a meet day changed; updates any non-overridden fees to
    /// match the meet day's billable hours and date. Index is guarded to
    /// prevent out-of-bounds access.
    func meetDayChanged(atIndex: Int){
        guard days.indices.contains(atIndex) else { return }
        let meetDay = days[atIndex]
        for judge in judges {
            if let fee = judge.fees.first(where: { $0.getMeetDayUUID() == meetDay.getUUID() }) {
                let excluded = fee.exclude ?? false
                if !excluded && !fee.hoursOverridden {
                    fee.hours = meetDay.totalBillableTimeInHours()
                    fee.date = meetDay.meetDate
                }
            }
        }
    }
    
    /// Remove a meet day and any associated fees from judges. Index is guarded.
    func removeMeetDay(at index: Int) {
        guard days.indices.contains(index) else { return }
        let uuid = self.days[index].getUUID()

        for judge in self.judges {
            judge.fees.removeAll(where: { $0.getMeetDayUUID() == uuid })
        }

        self.days.remove(at: index)
    }
    
    /// Remove a judge at the given index if valid.
    func removeJudgeAt(index: Int) {
        guard judges.indices.contains(index) else { return }
        self.judges.remove(at: index)
    }
    
    func totalJudgeFeesAndExpenses() -> Float{
        var total: Float = 0.0
        for judge in self.judges {
            total += judge.totalCost()
        }
        return total
    }
    
    func totalJudgeFees() -> Float{
        var total: Float = 0.0
        for judge in self.judges {
            total += judge.totalFees()
        }
        return total
    }
    
    /// Returns the judge's fee total for the given day index if present. The
    /// dayIndex is validated to prevent OOB access.
    func judgesFeeForDay(dayIndex: Int, judge: Judge) -> Float{
        guard days.indices.contains(dayIndex) else { return 0.0 }
        let date = days[dayIndex].meetDate
        if let fee = judge.fees.first(where: { $0.date == date }){
            return fee.getFeeTotal()
        } else {
            return 0.0
        }
    }
    
    func totalJudgesFeeForDay(dayIndex: Int) -> Float{
        var total: Float = 0.0
        for judge in judges{
            total += judgesFeeForDay(dayIndex: dayIndex, judge: judge)
        }
        return total
    }
    
    func totalBillableJudgeHours() -> Float{
        var total: Float = 0.0
        for judge in judges{
            total += judge.totalBillableHours()
        }
        return total
    }
}
