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

    struct SessionOverlapConflict: Equatable {
        let judgeName: String
        let conflictingSessionName: String
    }
    
    /// Federal mileage rates keyed by the date each rate took effect.
    static let FED_MILEAGE_RATE_SCHEDULE: [(effectiveDate: Date, rate: Float)] = [
        (effectiveDate: makeMileageRateDate(year: 2016, month: 1, day: 1), rate: 0.54),
        (effectiveDate: makeMileageRateDate(year: 2017, month: 1, day: 1), rate: 0.535),
        (effectiveDate: makeMileageRateDate(year: 2018, month: 1, day: 1), rate: 0.545),
        (effectiveDate: makeMileageRateDate(year: 2019, month: 1, day: 1), rate: 0.58),
        (effectiveDate: makeMileageRateDate(year: 2020, month: 1, day: 1), rate: 0.575),
        (effectiveDate: makeMileageRateDate(year: 2021, month: 1, day: 1), rate: 0.56),
        (effectiveDate: makeMileageRateDate(year: 2022, month: 1, day: 1), rate: 0.625),
        (effectiveDate: makeMileageRateDate(year: 2023, month: 1, day: 1), rate: 0.655),
        (effectiveDate: makeMileageRateDate(year: 2024, month: 1, day: 1), rate: 0.67),
        (effectiveDate: makeMileageRateDate(year: 2025, month: 1, day: 1), rate: 0.70),
        (effectiveDate: makeMileageRateDate(year: 2026, month: 1, day: 1), rate: 0.725),
        (effectiveDate: makeMileageRateDate(year: 2026, month: 7, day: 1), rate: 0.76)
    ]
    
    /// Maximum daily expense considered expensible for a single-room request.
    /// Stored as `Float` to match other monetary calculations in the model.
    static let SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS: Float = 107.0
    
    private static func makeMileageRateDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }

    /// Returns the mileage rate for a given date using the schedule above.
    /// If there is no exact change-date match this function returns the most
    /// recent rate whose effective date is <= the requested date. If there is
    /// no earlier rate (requested date is before our table), the earliest
    /// available rate is returned.
    static func getMileageRate(forDate: Date) -> Float {
        if let best = Meet.FED_MILEAGE_RATE_SCHEDULE
            .filter({ $0.effectiveDate <= forDate })
            .max(by: { $0.effectiveDate < $1.effectiveDate }) {
            return best.rate
        }

        return Meet.FED_MILEAGE_RATE_SCHEDULE.min(by: { $0.effectiveDate < $1.effectiveDate })?.rate ?? 0.76
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
    
    /// Add a meet day without assigning any judges to that day's sessions.
    /// Judges must be assigned manually per session after the day is added.
    func addMeetDay(day: MeetDay) {
        self.days.append(day)
    }

    /// Adds a new session to `day` without assigning any judges to it.
    /// Judges must be assigned manually after the session is created.
    func addSession(_ session: Session, to day: MeetDay) {
        day.sessions.append(session)
    }

    /// Removes a session from `day`, and any fees tied to it. Refuses to
    /// remove a day's last remaining session (a day must always have >= 1
    /// session) - returns `false` in that case.
    @discardableResult
    func removeSession(_ session: Session, from day: MeetDay) -> Bool {
        guard day.sessions.count > 1, let index = day.sessions.firstIndex(where: { $0 === session }) else {
            return false
        }
        let sessionUUID = session.getUUID()
        for judge in judges {
            judge.fees.removeAll(where: { $0.getSessionUUID() == sessionUUID })
        }
        day.sessions.remove(at: index)
        return true
    }

    /// Reasons a judge can't be assigned to a session.
    enum SessionAssignmentError: Error {
        /// The judge already has a fee for `Session` that overlaps the
        /// candidate session's time range (a judge can't work two
        /// concurrent sessions).
        case overlappingSession(Session)
    }

    enum SessionChangeError: Error {
        /// One or more currently-assigned judges would become double-booked
        /// if this session's new time range were saved.
        case overlappingAssignments([SessionOverlapConflict])
    }

    /// Assigns `judge` to `session` (creates a fee), validating that they
    /// don't already have an overlapping session assigned that day. A
    /// no-op (returns `.success`) if the judge is already assigned.
    @discardableResult
    func assignJudge(_ judge: Judge, to session: Session, in day: MeetDay) -> Result<Void, SessionAssignmentError> {
        if judge.fees.contains(where: { $0.getSessionUUID() == session.getUUID() }) {
            return .success(())
        }

        if let conflict = conflictingSession(for: judge, in: day, candidate: session) {
            return .failure(.overlappingSession(conflict))
        }

        if let fee = Fee(date: day.meetDate, hours: session.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID(), sessionUUID: session.getUUID()) {
            judge.fees.append(fee)
        } else {
            os_log("Failed to create Fee for judge %{public}@ for session %{public}@", log: OSLog.default, type: .error, judge.name, session.name)
        }
        return .success(())
    }

    /// Unassigns `judge` from `session` (removes their fee for it, if any).
    func unassignJudge(_ judge: Judge, from session: Session) {
        judge.fees.removeAll(where: { $0.getSessionUUID() == session.getUUID() })
    }

    /// Finds an existing session (other than `candidate`) on `day` that
    /// `judge` is already assigned to and that overlaps `candidate`'s time
    /// range, if any.
    private func conflictingSession(for judge: Judge, in day: MeetDay, candidate: Session) -> Session? {
        let candidateUUID = candidate.getUUID()
        return day.sessions.first { other in
            other !== candidate
                && other.getUUID() != candidateUUID
                && other.overlaps(with: candidate)
                && judge.fees.contains(where: { $0.getSessionUUID() == other.getUUID() })
        }
    }

    /// Validates a proposed session edit before it is applied to the live
    /// `Session` object. This allows UI callers to reject time changes that
    /// would double-book already-assigned judges without mutating model state.
    @discardableResult
    func validateSessionChange(_ session: Session, in day: MeetDay) -> Result<Void, SessionChangeError> {
        guard days.contains(where: { $0 === day }) else { return .success(()) }

        let conflicts = judges.compactMap { judge -> SessionOverlapConflict? in
            guard judge.fees.contains(where: { $0.getSessionUUID() == session.getUUID() }) else {
                return nil
            }
            guard let conflict = conflictingSession(for: judge, in: day, candidate: session) else {
                return nil
            }
            return SessionOverlapConflict(judgeName: judge.name, conflictingSessionName: conflict.name)
        }

        if conflicts.isEmpty {
            return .success(())
        }

        return .failure(.overlappingAssignments(conflicts))
    }
    
    /// Add a judge to the meet and append fees for every session on every
    /// existing meet day.
    func addJudge(judge: Judge){
        for day in self.days {
            for session in day.sessions {
                if let fee = Fee(date: day.meetDate, hours: session.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID(), sessionUUID: session.getUUID()) {
                    judge.fees.append(fee)
                } else {
                    os_log("Failed to create Fee for judge %{public}@ when adding to meet", log: OSLog.default, type: .error, judge.name)
                }
            }
        }
        self.judges.append(judge)
    }
    
    /// Called when a meet day's own date changes (not any session's time
    /// range); re-syncs the date of every fee tied to that day so
    /// invoices/reports stay in sync. Hours are governed by each session's
    /// own time range and are untouched by a pure date change. Index is
    /// guarded to prevent out-of-bounds access.
    func meetDayChanged(atIndex: Int){
        guard days.indices.contains(atIndex) else { return }
        let meetDay = days[atIndex]
        let dayUUID = meetDay.getUUID()
        for judge in judges {
            for fee in judge.fees where fee.getMeetDayUUID() == dayUUID {
                if !(fee.exclude ?? false) {
                    fee.date = meetDay.meetDate
                }
            }
        }
    }

    /// Called when a session's own time range/breaks changed after validation
    /// has already succeeded; re-syncs the hours (and date) of the one fee
    /// each judge has for that specific session.
    func sessionChanged(_ session: Session, in day: MeetDay){
        guard days.contains(where: { $0 === day }) else { return }
        let sessionUUID = session.getUUID()
        for judge in judges {
            if let fee = judge.fees.first(where: { $0.getSessionUUID() == sessionUUID }) {
                let excluded = fee.exclude ?? false
                if !excluded && !fee.hoursOverridden {
                    fee.hours = session.totalBillableTimeInHours()
                }
                if !excluded {
                    fee.date = day.meetDate
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
    
    /// Returns the sum of the judge's fee(s) for the given day index (there
    /// may be more than one now a day can have multiple sessions). The
    /// dayIndex is validated to prevent OOB access.
    func judgesFeeForDay(dayIndex: Int, judge: Judge) -> Float{
        guard days.indices.contains(dayIndex) else { return 0.0 }
        let dayUUID = days[dayIndex].getUUID()
        return judge.fees.filter { $0.getMeetDayUUID() == dayUUID }.reduce(0.0) { $0 + $1.getFeeTotal() }
    }
    
    func totalJudgesFeeForDay(dayIndex: Int) -> Float{
        var total: Float = 0.0
        for judge in judges{
            total += judgesFeeForDay(dayIndex: dayIndex, judge: judge)
        }
        return total
    }

    func assignedJudgeCountForDay(dayIndex: Int) -> Int {
        guard days.indices.contains(dayIndex) else { return 0 }
        let dayUUID = days[dayIndex].getUUID()
        return judges.filter { judge in
            judge.fees.contains(where: { $0.getMeetDayUUID() == dayUUID })
        }.count
    }
    
    func totalBillableJudgeHours() -> Float{
        var total: Float = 0.0
        for judge in judges{
            total += judge.totalBillableHours()
        }
        return total
    }
}
