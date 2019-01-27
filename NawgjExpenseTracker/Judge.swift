//
//  Judge.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/7/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Judge: Codable {
    
    enum Level : Int, Codable {
        case FourToFive = 0
        case SixToEight = 1
        case FourToEight = 2
        case Nine = 3
        case Ten = 4
        case National = 5
        case Brevet = 6
        
        var description: String {
            switch self {
                case .FourToFive : return "Levels 4 and 5"
                case .SixToEight : return "Levels 6, 7 and 8"
                case .FourToEight : return "Levels 4 to 8"
                case .Nine : return "Level 9"
                case .Ten : return "Level 10"
                case .National : return "National"
                case .Brevet : return "Brevet"
            }
        }
        
        var fullDescription: String {
            switch self {
            case .FourToFive : return "Levels 4 and 5 (" + String(format: "$%0.1f/hr)", rate)
            case .SixToEight : return "Levels 6, 7 and 8 (" + String(format: "$%0.1f/hr)", rate)
            case .FourToEight : return "Levels 4 to 8 (" + String(format: "$%0.1f/hr)", rate)
            case .Nine : return "Level 9 (" + String(format: "$%0.1f/hr)", rate)
            case .Ten : return "Level 10 (" + String(format: "$%0.1f/hr)", rate)
            case .National : return "National (" + String(format: "$%0.1f/hr)", rate)
            case .Brevet : return "Brevet (" + String(format: "$%0.1f/hr)", rate)
            }
        }
        
        var rate: Float {
            switch self {
                case .FourToFive : return 18.0
                case .SixToEight : return 20.0
                case .FourToEight : return 22.0
                case .Nine : return 26.0
                case .Ten : return 30.0
                case .National : return 33.0
                case .Brevet : return 36.0
            }
        }
        
        static func valueFor(description: String) -> Level?{
            switch description{
            case Level.FourToFive.description : return .FourToFive
            case Level.SixToEight.description : return .SixToEight
            case Level.FourToEight.description : return .FourToEight
            case Level.Nine.description : return .Nine
            case Level.Ten.description : return .Ten
            case Level.National.description : return .National
            case Level.Brevet.description : return .Brevet
            case Level.FourToFive.fullDescription : return .FourToFive
            case Level.SixToEight.fullDescription : return .SixToEight
            case Level.FourToEight.fullDescription : return .FourToEight
            case Level.Nine.fullDescription : return .Nine
            case Level.Ten.fullDescription : return .Ten
            case Level.National.fullDescription : return .National
            case Level.Brevet.fullDescription : return .Brevet
            default : return nil
            }
        }
        
        static var count: Int { return Level.Brevet.rawValue + 1}
    }
    
    // MARK: Properties
    var name : String
    var level : Level
    var expenses : Array<Expense>
    var fees : Array<Fee>
    private var notes : String?
    private var paid : Bool?
    
    
    //MARK: Initialization
    init(name: String, level: Level, expenses: Array<Expense>, fees: Array<Fee>, notes: String, paid: Bool) {
        // Initialize stored properties.
        self.name = name
        self.level = level
        self.expenses = expenses
        self.fees = fees
        self.notes = notes
        self.paid = paid
    }
    
    required convenience init(name: String, level: Level, expenses: Array<Expense>, fees: Array<Fee>) {
        self.init(name: name, level: level, expenses: expenses, fees: fees, notes: "", paid: false)
    }
    
    required convenience init?(name: String, level: Level, fees: Array<Fee>) {
        let expenseDate = (fees.isEmpty ? Date() : fees.last?.date)!
        
        let expenses = [
            Expense(type: .Mileage, date: expenseDate),
            Expense(type: .Parking, date: expenseDate),
            Expense(type: .Toll, date: expenseDate),
            Expense(type: .Transportation, date: expenseDate),
            Expense(type: .Airfare, date: expenseDate),
            Expense(type: .Meals, date: expenseDate),
            Expense(type: .Other, date: expenseDate)
        ]
        
        self.init(name: name, level: level, expenses: expenses as! Array<Expense>, fees: fees)
    }
    
    func totalCost() -> Float {
        return self.totalFees() + self.totalExpenses()
    }
    
    func totalExpenses() -> Float {
        var total : Float = 0.0
        
        for expense in expenses {
            total += expense.getExpenseTotal()
        }
        
        return total
    }
    
    func totalFees() -> Float {
        var totalFees : Float = 0.0
        
        for fee in fees {
            totalFees += fee.getFeeTotal()
        }
        
        return totalFees
    }
    
    func totalBillableHours() -> Float {
        var totalHours : Float = 0.0
        
        for fee in fees {
            totalHours += fee.getHours()
        }
        
        return totalHours
    }
    
    func changeLevel(level: Level){
        self.level = level
        for fee in self.fees{
            fee.rate = self.level.rate
        }
    }
    
    func getNotes() -> String{
        return notes ?? ""
    }
    
    func isPaid() -> Bool{
        return paid ?? false
    }
    
    func setPaid(_ paid : Bool){
        self.paid = paid
    }
    
    func setNotes(_ notes : String){
        self.notes = notes
    }
    
    func getFeesFor(date: Date) -> Float{
        if let fee = fees.first(where: {$0.date == date}){
            return fee.getFeeTotal()
        }
        else{
            return 0
        }
    }
}
