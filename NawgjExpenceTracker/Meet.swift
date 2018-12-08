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
    
    //MARK: Properties
    var name: String            // Identifies the name of the meet
    var days: Array<MeetDay>    // The specific meet days; 1 or more days
    var judges: Array<Judge>    // The Judges that worked at the meet
    var startDate: Date         // The first day of the meet
    var levels: String        // The levels competing at this meet
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("Meets")
    
    //MARK: Types
    struct PropertyKey {
        static let name = "Name"
        static let days = "Days"
        static let judges = "Judges"
        static let startDate = "Start Date"
        static let levels = "Levels"
    }
    
    //MARK: Initialization
    init?(name: String, days: Array<MeetDay>, judges: Array<Judge>, startDate: Date, levels: String) {
        // Initialization should fail if there is an empty name
        guard !name.isEmpty else {
            return nil
        }
        
        if levels.isEmpty {
            _ = ""
        }
        
        // Initialize stored properties.
        self.name = name
        self.days = days
        self.judges = judges
        self.startDate = startDate
        self.levels = levels
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(days, forKey: PropertyKey.days)
        aCoder.encode(judges, forKey: PropertyKey.judges)
        aCoder.encode(startDate, forKey: PropertyKey.startDate)
        aCoder.encode(levels, forKey: PropertyKey.levels)
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
        
        guard let levels = aDecoder.decodeObject(forKey: PropertyKey.levels) as? String else{
            os_log("Unable to decode the levels for a Meet object.", log: OSLog.default, type: .debug)
            return nil
        }
        // Must call designated initializer.
        self.init(name: name, days: days, judges: judges, startDate: startDate, levels: levels)
    }
    
    func totalCost() -> Float {
        var totalCost : Float = 0.0
        
        for judge in self.judges {
            totalCost += judge.totalCost()
        }
        
        return totalCost
    }
    
    func totalHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalTimeInHours()
        }
        
        return totalHours
    }
    
    func totalBillableHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalBillableTimeInHours()
        }
        
        return totalHours
    }
}
