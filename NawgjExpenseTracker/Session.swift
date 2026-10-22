//
//  Session.swift
//  NawgjExpenseTracker
//
//  Represents a single concurrent judging area within a `MeetDay` (e.g. one
//  apparatus rotation running in parallel with another at a bigger meet).
//  Introduced so a meet day can be split into one or more Sessions, each
//  with its own start/end time and breaks, and each judge is billed per
//  Session they actually worked rather than once per day.
//
//  See .github/SESSIONS_FEATURE_PLAN.md for the full feature plan.
//

import Foundation

/// Shared time/billing math for a countable block of judging time.
/// Extracted as a protocol extension so `Session` doesn't have to duplicate
/// `MeetDay`'s original rounding and minimum-billing-hours rules.
protocol BillableTimeRange {
    var startTime: Date { get }
    var endTime: Date { get }
    var breaks: Int { get }
    var breakTimeInMins: Int? { get }
}

extension BillableTimeRange {
    /// Total time between start and end, rounded to the nearest quarter hour
    /// (see `MeetDay.totalTimeInHours(startTime:endTime:)` for the original
    /// rounding rule this mirrors).
    func totalTimeInHours() -> Float {
        let timeInterval = endTime.timeIntervalSince(startTime)
        let timeInHours = timeInterval / 3600
        var hours = floor(timeInHours)
        let remainingMinutes = timeInHours.truncatingRemainder(dividingBy: 1)

        if remainingMinutes > 0.25 && remainingMinutes <= 0.75 {
            hours += 0.5
        } else if remainingMinutes > 0.75 {
            hours += 1
        }

        return Float(hours)
    }

    /// Total break time in hours (breaks count * per-break minutes).
    func breakTimeInHours() -> Float {
        return Float(breaks * (breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS)) / 60.0
    }

    /// Total billable time in hours: total time minus break time (capped at
    /// `MeetDay.MAX_BREAK_TIME_HOURS`), floored at `MeetDay.MIN_BILLING_HOURS`.
    func totalBillableTimeInHours() -> Float {
        return max(
            MeetDay.MIN_BILLING_HOURS,
            totalTimeInHours() - min(breakTimeInHours(), MeetDay.MAX_BREAK_TIME_HOURS)
        )
    }
}

class Session: Codable, BillableTimeRange {

    static let DEFAULT_NAME = "Session 1"

    // MARK: Properties
    var name: String
    var startTime: Date
    var endTime: Date
    var breaks: Int
    var breakTimeInMins: Int?
    var uuid: String?

    // MARK: Initialization
    init(name: String, startTime: Date, endTime: Date, breaks: Int, breakTimeInMins: Int?, uuid: String? = nil) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.breaks = breaks
        self.breakTimeInMins = breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS
        self.uuid = uuid ?? UUID().uuidString
    }

    /// Convenience initializer for a brand-new default session covering a
    /// full day's time range, mirroring the defaults the old single-range
    /// `MeetDay` used to use.
    convenience init(startTime: Date, endTime: Date) {
        self.init(name: Session.DEFAULT_NAME, startTime: startTime, endTime: endTime, breaks: 0, breakTimeInMins: MeetDay.DEFAULT_BREAK_TIME_MINS)
    }

    /// Retrieves the UUID for the current instance, generating one if it
    /// doesn't already exist (mirrors `MeetDay.getUUID()`).
    func getUUID() -> String {
        if uuid == nil {
            uuid = UUID().uuidString
        }
        return uuid!
    }

    /// Whether this session's time range overlaps another session's range.
    /// Used to enforce the "a judge can't work two overlapping sessions in
    /// the same day" rule.
    func overlaps(with other: Session) -> Bool {
        return startTime < other.endTime && other.startTime < endTime
    }
}

/// `Session` has a natural stable identifier (its uuid), so use it directly
/// for SwiftUI `List`/`ForEach` purposes.
extension Session: Identifiable {
    var id: String { getUUID() }
}
