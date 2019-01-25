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
        return MeetDay.totalTimeInHours(startTime: startTime, endTime: endTime)
    }
    
    static func totalTimeInHours(startTime : Date, endTime : Date) -> Float {
        let timeInterval = endTime.timeIntervalSince(startTime)
        let timeInHours = timeInterval / 3600
        var hours = floor(timeInHours)
        let remainingMinutes = timeInHours.truncatingRemainder(dividingBy: 1)
        
        if remainingMinutes > 0.25 && remainingMinutes <= 0.75{
            hours += 0.5
        }
        else if remainingMinutes > 0.75{
            hours += 1
        }
        
        return Float(hours)
    }
    
    func breakTimeInHours() -> Float {
        return MeetDay.breakTimeInHours(breaks: breaks)
    }
    
    static func breakTimeInHours(breaks : Int) -> Float {
        return Float(breaks) * MeetDay.BREAK_TIME_HOURS
    }
    
    func totalBillableTimeInHours() -> Float {
        return MeetDay.totalBillableTimeInHours(startTime: startTime, endTime: endTime, breaks: breaks)
    }
    
    static func totalBillableTimeInHours(startTime : Date, endTime : Date, breaks : Int) -> Float {
        return max(MeetDay.MIN_BILLING_HOURS, totalTimeInHours(startTime: startTime, endTime: endTime) - breakTimeInHours(breaks: breaks))
    }
}
