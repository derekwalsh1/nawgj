//
//  MeetDay.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDay: NSObject, NSCoding {
    
    static let BREAK_TIME_HOURS : Float = 0.5
    static let MIN_BILLING_HOURS : Float = 3.0
    static let DATE_FORMAT : String = "MMMM dd yyyy"
    
    // MARK: Properties
    var meetDate: Date
    var startTime: Date
    var endTime : Date
    var breaks : Int
    
     //MARK: Types
    struct PropertyKey {
        static let date = "date"
        static let startTime = "Start Time"
        static let endTime = "End Time"
        static let breaks = "Breaks"
    }
    
    //MARK: Initialization
    init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int) {
        
        // Initialize stored properties.
        self.meetDate = meetDate
        self.startTime = startTime
        self.endTime = endTime
        self.breaks = breaks
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(meetDate, forKey: PropertyKey.date)
        aCoder.encode(startTime, forKey: PropertyKey.startTime)
        aCoder.encode(endTime, forKey: PropertyKey.endTime)
        aCoder.encode(breaks, forKey: PropertyKey.breaks)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // Guard against not being able to decode values for required properties; the initializer should fail.
        guard let meetDate = aDecoder.decodeObject(forKey: PropertyKey.date) as? Date else {
            os_log("Unable to decode the date for a MeetDay object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let startTime = aDecoder.decodeObject(forKey: PropertyKey.startTime) as? Date else{
            os_log("Unable to decode the start time for a MeetDay object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let endTime = aDecoder.decodeObject(forKey: PropertyKey.endTime) as? Date else{
            os_log("Unable to decode the end time for a MeetDay object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let breaks = aDecoder.decodeObject(forKey: PropertyKey.breaks) as? Int else{
            os_log("Unable to decode the breaks for a MeetDay object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Must call designated initializer.
        self.init(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks)
    }

}
