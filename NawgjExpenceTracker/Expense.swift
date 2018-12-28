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
    
    enum ExpenseType : Int {
        case Mileage
        case Meals
        case Toll
        case Airfare
        case Transportation
        case Parking
        case Other
        
        var description: String {
            switch self {
            case .Mileage : return "Mileage"
            case .Meals : return "Meals"
            case .Toll : return "Tolls/Bridges"
            case .Airfare : return "Airfare"
            case .Transportation : return "Transportation"
            case .Parking : return "Parking"
            case .Other : return "Other Expenses"
            }
        }
        
        static var count: Int { return ExpenseType.Other.rawValue + 1}
    }
    
    // MARK: Properties
    var type : ExpenseType
    var amount : Float
    var notes : String = ""
    
    //MARK: Types
    struct PropertyKey {
        static let type = "Type"
        static let amount = "Amount"
        static let notes = "Notes"
    }
    
    //MARK: Initialization
    init(type: ExpenseType, amount: Float, notes: String ) {
        // Initialize stored properties.
        self.type = type
        self.amount = amount
        self.notes = notes
    }
    
    required convenience init?(type: ExpenseType) {
        self.init(type: type, amount: 0.0 as Float, notes: "")
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(type.rawValue, forKey: PropertyKey.type)
        aCoder.encode(amount, forKey: PropertyKey.amount)
        aCoder.encode(notes, forKey: PropertyKey.notes)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let typeRawValue = aDecoder.decodeInteger(forKey: PropertyKey.type)
        let amount = aDecoder.decodeFloat(forKey: PropertyKey.amount)
        let notes = aDecoder.decodeObject(forKey: PropertyKey.notes) as! String
        
        // Must call designated initializer.
        self.init(type: ExpenseType.init(rawValue: typeRawValue)!, amount: amount, notes: notes)
    }
}
