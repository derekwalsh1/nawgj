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
    
    static let BREAK_TIME_HOURS : Float = 0.5
    static let MIN_BILLING_HOURS : Float = 3.0
    static let DATE_FORMAT : String = "MMMM dd yyyy"
    
    // MARK: Properties
    var meetDate: Date
    var startTime: Date
    var endTime : Date
    var breaks : Int
    
    //MARK: Initialization
    init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int) {
        // Initialize stored properties.
        self.meetDate = meetDate
        self.startTime = startTime
        self.endTime = endTime
        self.breaks = breaks
    }
    
    func totalTimeInHours() -> Float {
        return Float(endTime.timeIntervalSince(startTime)) / 3600
    }
    
    static func totalTimeInHours(startTime : Date, endTime : Date) -> Float {
        return Float(endTime.timeIntervalSince(startTime)) / 3600
    }
    
    func breakTimeInHours() -> Float {
        return Float(breaks) * MeetDay.BREAK_TIME_HOURS
    }
    
    static func breakTimeInHours(breaks : Int) -> Float {
        return Float(breaks) * MeetDay.BREAK_TIME_HOURS
    }
    
    func totalBillableTimeInHours() -> Float {
        return max(MeetDay.MIN_BILLING_HOURS, totalTimeInHours() - breakTimeInHours()) as Float
    }
    
    static func totalBillableTimeInHours(startTime : Date, endTime : Date, breaks : Int) -> Float {
        return max(MeetDay.MIN_BILLING_HOURS, totalTimeInHours(startTime: startTime, endTime: endTime) - breakTimeInHours(breaks: breaks))
    }
}
