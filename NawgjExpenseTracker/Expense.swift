//
//  Expense.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Expense: Codable {
    
    enum ExpenseType : Int, Codable {
        case Mileage
        case Meals
        case Toll
        case Airfare
        case Transportation
        case Parking
        case Lodging
        case Other
        
        var description: String {
            switch self {
            case .Mileage : return "Mileage"
            case .Meals : return "Meals"
            case .Toll : return "Tolls/Bridges"
            case .Airfare : return "Airfare"
            case .Transportation : return "Transportation"
            case .Parking : return "Parking"
            case .Lodging : return "Lodging"
            case .Other : return "Other Expenses"
            }
        }
        
        static var count: Int { return ExpenseType.Other.rawValue + 1}
    }
    
    // MARK: Properties
    var type : ExpenseType
    var amount : Float
    var notes : String = ""
    var date : Date?
    
    // Mileage related expenses
    var mileageRate : Float
    var isCustomMileageRate : Bool? = false
    
    // For lodging only
    var isPrivateLodgingRequested : Bool? = false
    var totalNights : Int? = 1
    var amountPerNight : Float? = 0
    
    //MARK: Initialization
    init(type: ExpenseType, amount: Float, notes: String, date: Date, mileageRate: Float, isCustomMileageRate : Bool, isPrivateLodgingRequested : Bool, totalNights : Int, amountPerNight : Float) {
        
        self.type = type
        self.amount = amount
        self.notes = notes
        self.date = date
        self.mileageRate = mileageRate
        self.isCustomMileageRate = isCustomMileageRate
        self.isPrivateLodgingRequested = isPrivateLodgingRequested
        self.totalNights = totalNights
        self.amountPerNight = amountPerNight
    }
    
    required convenience init(type: ExpenseType, amount: Float, notes: String, date: Date, mileageRate: Float) {
        self.init(type: type, amount: amount, notes: notes, date: date, mileageRate: mileageRate, isCustomMileageRate:false, isPrivateLodgingRequested: false, totalNights: 0, amountPerNight: 0)
    }
    
    required convenience init(type: ExpenseType, amount: Float, notes: String, date: Date ) {
        // Initialize stored properties.
        var mileageRate = 0.0 as Float
        if Meet.FED_MILEAGE_RATES.keys.contains(Calendar.current.component(.year, from: date)){
            mileageRate = Meet.FED_MILEAGE_RATES[Calendar.current.component(.year, from: date)]!
        }
        else{
            mileageRate = (Meet.FED_MILEAGE_RATES.reversed().first?.value)!
        }
        self.init(type: type, amount: amount, notes: notes, date: date, mileageRate: mileageRate, isCustomMileageRate:false, isPrivateLodgingRequested: false, totalNights: 0, amountPerNight: 0)
    }
    
    required convenience init?(type: ExpenseType, date: Date) {
        self.init(type: type, amount: 0.0 as Float, notes: "", date: date)
    }
    
    func getExpenseTotal() -> Float{
        switch type{
        case .Mileage:
            return amount * mileageRate
        case .Lodging:
            return (Meet.SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS - (amountPerNight ?? 0)) * Float(totalNights ?? 0)
        default:
            return amount
        }
    }
}
