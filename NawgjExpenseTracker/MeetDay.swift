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
    static let MIN_BILLING_HOURS : Float = 2.0
    static let DATE_FORMAT : String = "MMMM dd yyyy"
    static let MAX_BREAK_TIME_MINS : Int = 120
    
    // MARK: Properties
    var meetDate: Date
    var startTime: Date
    var endTime : Date
    var breaks : Int
    var uuid : String?
    var breakTimeInMins : Int? = MeetDay.DEFAULT_BREAK_TIME_MINS
    
    //MARK: Initialization
    required convenience init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int) {
        self.init(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: MeetDay.DEFAULT_BREAK_TIME_MINS, id: UUID.init().uuidString)
    }
    
    required convenience init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int, breakTime: Int) {
        self.init(meetDate: meetDate, startTime: startTime, endTime: endTime, breaks: breaks, breakTime: breakTime, id: UUID.init().uuidString)
    }
    
    //MARK: Initialization
    init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int, breakTime: Int?, id: String) {
        // Initialize stored properties.
        self.meetDate = meetDate
        self.startTime = startTime
        self.endTime = endTime
        self.breaks = breaks
        self.uuid = id
        self.breakTimeInMins = breakTime ?? MeetDay.DEFAULT_BREAK_TIME_MINS
    }
    
    func totalTimeInHours() -> Float {
        return totalTimeInHours(startTime: startTime, endTime: endTime)
    }
    
    func getUUID() -> String{
        if uuid == nil{
            uuid = UUID.init().uuidString
        }
        
        return self.uuid!
    }
    
    func totalTimeInHours(startTime : Date, endTime : Date) -> Float {
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
        return Float(self.breaks * (breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS))/60.0
    }

    func totalBillableTimeInHours() -> Float {
        return totalBillableTimeInHours(startTime: startTime, endTime: endTime, breaks: breaks)
    }
    
    func totalBillableTimeInHours(startTime : Date, endTime : Date, breaks : Int) -> Float {
        return max(MeetDay.MIN_BILLING_HOURS, totalTimeInHours(startTime: startTime, endTime: endTime) - min(breakTimeInHours(), 2.0))
    }
}
