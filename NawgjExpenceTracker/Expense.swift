//
//  Expense.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Expense: NSObject, NSCoding {
    
    enum ExpenseType {
        case Meals
        case Toll
        case Airfare
        case Transportation
        case Parking
        case Other
        case MeetReferee
        case Fee
    }
    
    // MARK: Properties
    var type : ExpenseType
    var amount : Float
    var taxable : Bool
    var notes : String?
    
    //MARK: Types
    struct PropertyKey {
        static let type = "Type"
        static let amount = "Amount"
        static let notes = "Notes"
    }
    
    //MARK: Initialization
    init(type: ExpenseType, amount: Float, notes: String? ) {
        // If notes aren't provided (they are optional, then use an empty string
        if notes == nil { _ = ""}
        
        // Initialize stored properties.
        self.type = type
        self.amount = amount
        self.notes = notes
        
        switch self.type{
        case .Fee:
            self.taxable = true
            break
        default:
            self.taxable = false
        }
        
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type, forKey: PropertyKey.type)
        aCoder.encode(amount, forKey: PropertyKey.amount)
        aCoder.encode(notes, forKey: PropertyKey.notes)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let type = aDecoder.decodeObject(forKey: PropertyKey.type) as? ExpenseType else {
            os_log("Unable to decode the type of an Expense object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        let amount = aDecoder.decodeFloat(forKey: PropertyKey.amount)
        let notes = aDecoder.decodeObject(forKey: PropertyKey.notes) as? String
        
        // Must call designated initializer.
        self.init(type: type, amount: amount, notes: notes)
    }
}
