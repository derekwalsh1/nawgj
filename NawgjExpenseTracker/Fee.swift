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
    var hours : Float
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
