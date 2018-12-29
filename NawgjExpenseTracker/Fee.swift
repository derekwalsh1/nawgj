//
//  Fee.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Fee: Codable {
    
    // MARK: Properties
    var date : Date
    var hours : Float
    var notes : String?
    var rate : Float
    var rateOverridden : Bool
    var hoursOverridden : Bool
    
    //MARK: Initialization
    init(date: Date, hours: Float, rate: Float, rateOverridden: Bool, hoursOverridden: Bool, notes: String? ) {
        // If notes aren't provided (they are optional, then use an empty string
        if notes == nil { _ = ""}
        
        // Initialize stored properties.
        self.date = date
        self.hours = hours
        self.notes = notes
        self.rateOverridden = false
        self.hoursOverridden = false
        self.rate = rate
    }
    
    required convenience init?(date: Date, hours: Float, rate: Float, notes : String?){
        
        if notes == nil { _ = ""}
        self.init(date: date, hours: hours, rate: rate, rateOverridden: false, hoursOverridden: false, notes: notes)
    }
    
    func getFeeTotal() -> Float{
        return hours * rate
    }
}
