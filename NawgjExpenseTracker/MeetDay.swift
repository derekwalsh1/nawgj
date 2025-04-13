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
    
    // MARK: Initialization
    /// Initializes a `MeetDay` instance with the provided meet date, start time, end time,
    /// number of breaks, optional break time, and a unique identifier.
    /// - Parameters:
    ///   - meetDate: The date of the meet day.
    ///   - startTime: The start time of the meet day.
    ///   - endTime: The end time of the meet day.
    ///   - breaks: The number of breaks taken during the meet day.
    ///   - breakTime: The duration of each break in minutes (optional). If `nil`, the default break time is used.
    ///   - id: The unique identifier for the meet day.
    init(meetDate: Date, startTime: Date, endTime: Date, breaks: Int, breakTime: Int?, id: String) {
        // Initialize the meet date
        self.meetDate = meetDate
        // Initialize the start time of the meet
        self.startTime = startTime
        // Initialize the end time of the meet
        self.endTime = endTime
        // Initialize the number of breaks taken
        self.breaks = breaks
        // Assign the unique identifier to the instance
        self.uuid = id
        // Set the break time in minutes, using the provided value or the default if nil
        self.breakTimeInMins = breakTime ?? MeetDay.DEFAULT_BREAK_TIME_MINS
    }

    
    /// Computes the total time in hours for the meet day using the instance's start and end times.
    /// This is a convenience method that utilizes the `totalTimeInHours(startTime:endTime:)` method.
    /// - Returns: The total time in hours as a Float.
    func totalTimeInHours() -> Float {
        // Call the overloaded method with the instance's startTime and endTime properties.
        return totalTimeInHours(startTime: startTime, endTime: endTime)
    }

    
    /// Retrieves the UUID for the current instance. If a UUID does not already exist,
    /// this method generates a new UUID and stores it.
    /// - Returns: A unique identifier (UUID) as a String.
    func getUUID() -> String {
        // Check if the UUID is nil (not yet initialized)
        if uuid == nil {
            // Generate a new UUID and assign it to the `uuid` property
            uuid = UUID().uuidString
        }
        
        // Return the UUID (it is guaranteed to be non-nil at this point)
        return self.uuid!
    }
    
    /// Computes the total time to be billed in hours with granularity to the nearest quarter-hour.
    /// The method takes a start and end time, calculates the duration between them in hours, and
    /// adjusts the result to the nearest quarter-hour.
    /// - Parameters:
    ///   - startTime: The starting time of the meet day.
    ///   - endTime: The ending time of the meet day.
    /// - Returns: The total time in hours, rounded to the nearest quarter-hour, as a Float.
    func totalTimeInHours(startTime : Date, endTime : Date) -> Float {
        // Calculate the time interval in seconds between the start and end time
        let timeInterval = endTime.timeIntervalSince(startTime)
        
        // Convert the time interval from seconds to hours
        let timeInHours = timeInterval / 3600
        
        // Truncate the fractional hours to whole hours
        var hours = floor(timeInHours)
        
        // Extract the fractional part of the hours (remaining minutes as a fraction)
        let remainingMinutes = timeInHours.truncatingRemainder(dividingBy: 1)
        
        // Adjust the total hours to the nearest quarter-hour:
        // - Add 0.5 for fractions between 15 and 45 minutes.
        // - Add 1 for fractions above 45 minutes.
        if remainingMinutes > 0.25 && remainingMinutes <= 0.75 {
            hours += 0.5
        } else if remainingMinutes > 0.75 {
            hours += 1
        }
        
        // Return the total billed time as a Float
        return Float(hours)
    }

    
    /// Calculates the total break time in hours for the meet day.
    /// The total break time is derived by multiplying the number of breaks by the duration of each break
    /// (in minutes) and converting the result to hours.
    /// - Returns: The total break time in hours as a Float.
    func breakTimeInHours() -> Float {
        // Multiply the number of breaks by the duration of each break in minutes.
        // If `breakTimeInMins` is nil, use the default break time defined in `MeetDay.DEFAULT_BREAK_TIME_MINS`.
        // Convert the result from minutes to hours by dividing by 60.
        return Float(self.breaks * (breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS)) / 60.0
    }

    /// Calculates the total billable time in hours for the meet day using the instance's start time,
    /// end time, and number of breaks.
    /// This method acts as a convenience wrapper around the `totalBillableTimeInHours(startTime:endTime:breaks:)` method.
    /// - Returns: The total billable time in hours as a Float.
    func totalBillableTimeInHours() -> Float {
        // Call the overloaded `totalBillableTimeInHours` method using the instance's `startTime`, `endTime`, and `breaks` properties.
        return totalBillableTimeInHours(startTime: startTime, endTime: endTime, breaks: breaks)
    }

    
    /// Calculates the total billable time in hours for a meet day, taking breaks into account.
    /// The method ensures that the billable time is at least the minimum billing hours defined.
    /// - Parameters:
    ///   - startTime: The starting time of the meet day.
    ///   - endTime: The ending time of the meet day.
    ///   - breaks: The number of breaks taken during the meet day.
    /// - Returns: The total billable time in hours, as a Float.
    func totalBillableTimeInHours(startTime: Date, endTime: Date, breaks: Int) -> Float {
        // Calculate the total time in hours for the day, subtracting the lesser of:
        // - The break time in hours.
        // - A maximum of 2.0 hours.
        // Ensure the result is at least the minimum billing hours defined in `MeetDay.MIN_BILLING_HOURS`.
        return max(
            MeetDay.MIN_BILLING_HOURS,
            totalTimeInHours(startTime: startTime, endTime: endTime) - min(breakTimeInHours(), MeetDay.MAX_BREAK_TIME_HOURS)
        )
    }
}
