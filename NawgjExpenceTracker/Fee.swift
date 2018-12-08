//
//  Fee.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Fee: NSObject, NSCoding {
    
    // MARK: Properties
    var date : Date
    var hours : Float
    var notes : String?
    
    //MARK: Types
    struct PropertyKey {
        static let date = "Date"
        static let hours = "Hours"
        static let notes = "Notes"
    }
    
    //MARK: Initialization
    init(date: Date, hours: Float, notes: String? ) {
        // If notes aren't provided (they are optional, then use an empty string
        if notes == nil { _ = ""}
        
        // Initialize stored properties.
        self.date = date
        self.hours = hours
        self.notes = notes
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(hours, forKey: PropertyKey.hours)
        aCoder.encode(notes, forKey: PropertyKey.notes)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let date = aDecoder.decodeObject(forKey: PropertyKey.date) as? Date else {
            os_log("Unable to decode the date of an Expense object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let hours = aDecoder.decodeFloat(forKey: PropertyKey.hours)
        let notes = aDecoder.decodeObject(forKey: PropertyKey.notes) as? String
        
        // Must call designated initializer.
        self.init(date: date, hours: hours, notes: notes)
    }
}
