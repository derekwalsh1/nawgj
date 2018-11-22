//
//  Judge.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Judge: NSObject, NSCoding {
    
    enum Level : String {
        case FourToFive = "Levels 4 and 5"
        case SixToEight = "Levels 6, 7 and 8"
        case FourToEight = "Levels 4 to 8"
        case Nine = "Level 9"
        case Ten = "Level 10"
        case Brevet = "Brevet"
        case National = "National"
    }
    
    // MARK: Properties
    var name : String
    var level : Level
    var expenses : Array<Expense>
    
    //MARK: Types
    struct PropertyKey {
        static let name = "Name"
        static let level = "Level"
        static let expenses = "Expenses"
    }
    
    //MARK: Initialization
    init(name: String, level: Level, expenses: Array<Expense>) {
        // Initialize stored properties.
        self.name = name
        self.level = level
        self.expenses = expenses
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.name)
        aCoder.encode(level, forKey: PropertyKey.level)
        aCoder.encode(expenses, forKey: PropertyKey.expenses)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String else {
            os_log("Unable to decode the name of a Judge object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let level = aDecoder.decodeObject(forKey: PropertyKey.level) as? Level else{
            os_log("Unable to decode the level of a Judge object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let expenses = aDecoder.decodeObject(forKey: PropertyKey.expenses) as? Array<Expense> else{
            os_log("Unable to decode the expenses of a Judge object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        // Must call designated initializer.
        self.init(name: name, level: level, expenses: expenses)
    }
    
}
