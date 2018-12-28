//
//  Meet.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/22/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Meet: NSObject, NSCoding {
    
    static let FED_MILEAGE_RATE : Float = 0.545
    
    //MARK: Properties
    var name: String            // Identifies the name of the meet
    var days: Array<MeetDay>    // The specific meet days; 1 or more days
    var judges: Array<Judge>    // The Judges that worked at the meet
    var startDate: Date         // The first day of the meet
    var meetDescription: String // The levels competing at this meet or some meaningful description
    var location: String        // The location of the meet
    var mileageRate: Float      // The federal mileage rate used for this meet - may be different than the current rate depending on when the event and expenses occurred.
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("Meets")
    
    //MARK: Types
    struct PropertyKey {
        static let name = "Name"
        static let days = "Days"
        static let judges = "Judges"
        static let startDate = "Start Date"
        static let meetDescription = "Description"
        static let mileageRate = "Mileage Rate"
        static let location = "Location"
    }
    
    //MARK: Initialization
    init?(name: String, days: Array<MeetDay>, judges: Array<Judge>, startDate: Date, meetDescription: String?, mileageRate: Float, location: String?) {
        // Initialization should fail if there is an empty name
        guard !name.isEmpty else {
            return nil
        }
        
        if meetDescription == nil{
            _ = " "
        }
        
        if location == nil{
            _ = " "
        }
        
        // Initialize stored properties.
        self.name = name
        self.days = days
        self.judges = judges
        self.startDate = startDate
        self.meetDescription = meetDescription!
        self.location = location!
        self.mileageRate = mileageRate
    }
    
    required convenience init?(name: String, startDate: Date) {
        self.init(name: name, days: Array<MeetDay>(), judges: Array<Judge>(), startDate: startDate, meetDescription: " ", mileageRate: Meet.FED_MILEAGE_RATE, location: " ")
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(days, forKey: PropertyKey.days)
        aCoder.encode(judges, forKey: PropertyKey.judges)
        aCoder.encode(startDate, forKey: PropertyKey.startDate)
        aCoder.encode(meetDescription, forKey: PropertyKey.meetDescription)
        aCoder.encode(mileageRate, forKey: PropertyKey.mileageRate)
        aCoder.encode(location, forKey: PropertyKey.location)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        // Guard against not being able to decode values for required properties; the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name of a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let days = aDecoder.decodeObject(forKey: PropertyKey.days) as? Array<MeetDay> else{
            os_log("Unable to decode the days within a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let judges = aDecoder.decodeObject(forKey: PropertyKey.judges) as? Array<Judge> else{
            os_log("Unable to decode the Judges for a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let startDate = aDecoder.decodeObject(forKey: PropertyKey.startDate) as? Date else{
            os_log("Unable to decode the Start Date for a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let description = aDecoder.decodeObject(forKey: PropertyKey.meetDescription) as? String else{
            os_log("Unable to decode the description for a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let location = aDecoder.decodeObject(forKey: PropertyKey.location) as? String else{
            os_log("Unable to decode the location for a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        var mileageRate = aDecoder.decodeFloat(forKey: PropertyKey.mileageRate)
        
        if mileageRate == 0{
            mileageRate = Meet.FED_MILEAGE_RATE
        }
        // Must call designated initializer.
        self.init(name: name, days: days, judges: judges, startDate: startDate, meetDescription: description, mileageRate: mileageRate, location: location)
    }
    
    //MARK: Meet management and intergotation
    func totalCostOfMeet() -> Float {
        var totalCost : Float = 0.0
        
        for judge in self.judges {
            totalCost += judge.totalCost()
        }
        
        return totalCost
    }
    
    func totalMeetHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalTimeInHours()
        }
        
        return totalHours
    }
    
    func billableMeetHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalBillableTimeInHours()
        }
        
        return totalHours
    }
    
    func addMeetDay(day: MeetDay) {
        self.days.append(day)
        // add fees to judges for this day
        for judge in self.judges {
            judge.fees.append(Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: judge.level.rate, notes: "")!)
        }
    }
    
    func removeMeetDay(at: Int) {
        let date = self.days[at].meetDate
        
        for judge in self.judges {
            var idx : Int? = nil
            for (index, fee) in judge.fees.enumerated() {
                if fee.date == date {
                    idx = index
                }
            }
            if idx != nil {
                judge.fees.remove(at: idx!)
            }
        }
        
        self.days.remove(at: at)
    }
    
    func totalJudgeFeesAndExpenses() -> Float{
        var total : Float = 0.0
        
        for judge in self.judges {
            total += judge.totalCost()
        }
        
        return total
    }
}
