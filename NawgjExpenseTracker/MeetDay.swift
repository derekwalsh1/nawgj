//
//  MeetDay.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDay: Codable {
    
    static let DEFAULT_BREAK_TIME_MINS : Int = 30
    static let MIN_BILLING_HOURS : Float = 3.0
    static let DATE_FORMAT : String = "MMMM dd yyyy"
    static let MAX_BREAK_TIME_HOURS : Float = 2.0
    
    // MARK: Properties
    var meetDate: Date
    /// The concurrent judging areas ("Sessions") running on this day. Every
    /// day has at least one Session; legacy days (saved before this concept
    /// existed) are migrated to a single implicit Session on decode - see
    /// `init(from:)` below.
    var sessions: [Session]
    var uuid : String?

    // MARK: Legacy compatibility (display-only)
    //
    // These used to be this type's only time-range fields. They're kept as
    // computed properties - derived from `sessions` - purely so existing
    // day-level summary UI/reports that want "the" start/end/break count for
    // a day keep working without change. They are NOT the source of truth
    // for billing math any more; `sessions` is.
    var startTime: Date {
        sessions.map { $0.startTime }.min() ?? meetDate
    }
    var endTime: Date {
        sessions.map { $0.endTime }.max() ?? meetDate
    }
    var breaks: Int {
        sessions.reduce(0) { $0 + $1.breaks }
    }

    //MARK: Initialization
    required convenience init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int) {
        self.init(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: MeetDay.DEFAULT_BREAK_TIME_MINS, id: UUID.init().uuidString)
    }
    
    required convenience init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int, breakTime: Int) {
        self.init(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: breakTime, id: UUID.init().uuidString)
    }
    
    // MARK: Initialization
    /// Initializes a `MeetDay` instance with the provided meet date, start time, end time,
    /// number of breaks, optional break time, and a unique identifier. Creates a single
    /// default Session spanning the given time range.
    /// - Parameters:
    ///   - meetDate: The date of the meet day.
    ///   - startTime: The start time of the meet day's (only) session.
    ///   - endTime: The end time of the meet day's (only) session.
    ///   - breaks: The number of breaks taken during that session.
    ///   - breakTime: The duration of each break in minutes (optional). If `nil`, the default break time is used.
    ///   - id: The unique identifier for the meet day.
    init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int, breakTime: Int?, id: String) {
        self.meetDate = meetDate
        self.uuid = id
        self.sessions = [Session(name: Session.DEFAULT_NAME, startTime: startTime, endTime: endTime, breaks: breaks, breakTimeInMins: breakTime)]
    }

    /// Initializes a `MeetDay` with an explicit list of sessions.
    init(meetDate: Date, sessions: [Session], id: String) {
        self.meetDate = meetDate
        self.sessions = sessions
        self.uuid = id
    }

    // MARK: Codable
    //
    // Custom implementation (rather than relying on synthesized Codable) so
    // legacy JSON - saved before `sessions` existed - can be migrated
    // automatically: if no `sessions` array is present, one is synthesized
    // from the day's old start/end/breaks/breakTimeInMins fields.
    private enum CodingKeys: String, CodingKey {
        case meetDate, sessions, uuid
        case startTime, endTime, breaks, breakTimeInMins
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        meetDate = try container.decode(Date.self, forKey: .meetDate)
        uuid = try container.decodeIfPresent(String.self, forKey: .uuid)

        if let decodedSessions = try container.decodeIfPresent([Session].self, forKey: .sessions), !decodedSessions.isEmpty {
            sessions = decodedSessions
        } else {
            // Legacy migration: synthesize exactly one Session from this
            // day's old single time-range fields.
            let legacyStart = try container.decode(Date.self, forKey: .startTime)
            let legacyEnd = try container.decode(Date.self, forKey: .endTime)
            let legacyBreaks = try container.decode(Int.self, forKey: .breaks)
            let legacyBreakTime = try container.decodeIfPresent(Int.self, forKey: .breakTimeInMins)
            sessions = [Session(name: Session.DEFAULT_NAME, startTime: legacyStart, endTime: legacyEnd, breaks: legacyBreaks, breakTimeInMins: legacyBreakTime)]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(meetDate, forKey: .meetDate)
        try container.encode(sessions, forKey: .sessions)
        try container.encode(uuid, forKey: .uuid)
    }

    /// Retrieves the UUID for the current instance. If a UUID does not already exist,
    /// this method generates a new UUID and stores it.
    /// - Returns: A unique identifier (UUID) as a String.
    func getUUID() -> String {
        if uuid == nil {
            uuid = UUID().uuidString
        }
        return self.uuid!
    }

    /// Total time in hours across all of this day's sessions.
    func totalTimeInHours() -> Float {
        sessions.reduce(0) { $0 + $1.totalTimeInHours() }
    }

    /// Total break time in hours across all of this day's sessions.
    func breakTimeInHours() -> Float {
        sessions.reduce(0) { $0 + $1.breakTimeInHours() }
    }

    /// Total billable time in hours across all of this day's sessions (each
    /// session is floored at `MIN_BILLING_HOURS` individually).
    func totalBillableTimeInHours() -> Float {
        sessions.reduce(0) { $0 + $1.totalBillableTimeInHours() }
    }

    /// Whether `candidate` overlaps any existing session on this day (other
    /// than `excluding`, e.g. itself when editing in place).
    func hasOverlap(_ candidate: Session, excluding: Session? = nil) -> Bool {
        sessions.contains { session in
            if let excluding, session === excluding { return false }
            return session.overlaps(with: candidate)
        }
    }
}
