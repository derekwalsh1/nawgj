//
//  Fee.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Fee: Codable {
    
    // MARK: Properties
    var date : Date
    /// Billable (payable) hours for this fee - what's actually used for
    /// `getFeeTotal()`/`getHours()` and shown throughout the app. May be
    /// higher than `actualHours` when the per-judge, per-day minimum
    /// billing hours rule (see `Meet.recomputeBillableHours(for:day:)`)
    /// tops up a short day to `MeetDay.MIN_BILLING_HOURS`.
    var hours : Float
    /// The true hours worked for this fee's session: the session's own
    /// un-floored computed time for an auto-computed fee, or exactly what
    /// the user entered for a manually-overridden one (`hoursOverridden
    /// == true`). Never silently adjusted by the minimum-billing-hours
    /// rule, so a day's fees can always be correctly recomputed from
    /// scratch later (e.g. when another session is added/removed) without
    /// losing what was actually entered. Defaults to `hours` when decoding
    /// older saved data that predates this property.
    var actualHours : Float
    var notes : String?
    var rate : Float
    var rateOverridden : Bool
    var hoursOverridden : Bool
    var exclude : Bool? = false
    var meetDayUUID : String?
    /// The Session (within `meetDayUUID`'s day) this fee bills for. Optional
    /// only so old JSON (saved before Sessions existed) can decode; it is
    /// filled in for every fee during meet load/normalization once the
    /// owning day's sessions are known - see
    /// `MeetListManager.decodeAndNormalizeMeets`.
    var sessionUUID : String?
    
    //MARK: Initialization
    init(date: Date, hours: Float, rate: Float, rateOverridden: Bool, hoursOverridden: Bool, notes: String?, exclude: Bool, meetDayUUID: String, sessionUUID: String? = nil ) {
        // If notes aren't provided (they are optional, then use an empty string
        if notes == nil { _ = ""}
        
        // Initialize stored properties.
        self.date = date
        self.hours = hours
        self.actualHours = hours
        self.notes = notes
        self.rateOverridden = false
        self.hoursOverridden = false
        self.rate = rate
        self.exclude = exclude
        self.meetDayUUID = meetDayUUID
        self.sessionUUID = sessionUUID
    }
    
    required convenience init?(date: Date, hours: Float, rate: Float, notes : String?, meetDayUUID: String, sessionUUID: String? = nil){
        
        if notes == nil { _ = ""}
        self.init(date: date, hours: hours, rate: rate, rateOverridden: false, hoursOverridden: false, notes: notes, exclude: false, meetDayUUID: meetDayUUID, sessionUUID: sessionUUID)
    }

    // MARK: Codable
    //
    // Custom implementation so `actualHours` (added after this type first
    // shipped) defaults to the existing `hours` value when decoding older
    // saved meets that predate it, rather than failing to decode.
    private enum CodingKeys: String, CodingKey {
        case date, hours, actualHours, notes, rate, rateOverridden, hoursOverridden, exclude, meetDayUUID, sessionUUID
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        hours = try container.decode(Float.self, forKey: .hours)
        actualHours = try container.decodeIfPresent(Float.self, forKey: .actualHours) ?? hours
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        rate = try container.decode(Float.self, forKey: .rate)
        rateOverridden = try container.decode(Bool.self, forKey: .rateOverridden)
        hoursOverridden = try container.decode(Bool.self, forKey: .hoursOverridden)
        exclude = try container.decodeIfPresent(Bool.self, forKey: .exclude)
        meetDayUUID = try container.decodeIfPresent(String.self, forKey: .meetDayUUID)
        sessionUUID = try container.decodeIfPresent(String.self, forKey: .sessionUUID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(hours, forKey: .hours)
        try container.encode(actualHours, forKey: .actualHours)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(rate, forKey: .rate)
        try container.encode(rateOverridden, forKey: .rateOverridden)
        try container.encode(hoursOverridden, forKey: .hoursOverridden)
        try container.encodeIfPresent(exclude, forKey: .exclude)
        try container.encodeIfPresent(meetDayUUID, forKey: .meetDayUUID)
        try container.encodeIfPresent(sessionUUID, forKey: .sessionUUID)
    }
    
    func getFeeTotal() -> Float{
        return (exclude ?? false) ? 0.0 : hours * rate
    }
    
    func getHours() -> Float{
        return (exclude ?? false) ? 0.0 : hours
    }
    
    func getMeetDayUUID() -> String?{
        return meetDayUUID
    }
    
    func setMeetDayUUID(uuid: String){
        self.meetDayUUID = uuid
    }
    
    func getSessionUUID() -> String?{
        return sessionUUID
    }
    
    func setSessionUUID(uuid: String){
        self.sessionUUID = uuid
    }
}
