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
        case NGA_Local = 7
        case NGA_State = 8
        case NGA_Regional = 9
        case NGA_National = 10
        case NGA_Elite = 11
        
        var description: String {
            switch self {
                case .FourToFive : return "Levels 4 and 5"
                case .SixToEight : return "Levels 6, 7 and 8"
                case .FourToEight : return "Levels 4 to 8"
                case .Nine : return "Level 9"
                case .Ten : return "Level 10"
                case .National : return "National"
                case .Brevet : return "Brevet"
                case .NGA_Local : return "Local(NGA)"
                case .NGA_State : return "State(NGA)"
                case .NGA_Regional : return "Regional(NGA)"
                case .NGA_National : return "National(NGA)"
                case .NGA_Elite : return "Elite(NGA)"
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
            case .NGA_Local : return "Local(NGA)(" + String(format: "$%0.1f/hr)", rate)
            case .NGA_State : return "State(NGA)(" + String(format: "$%0.1f/hr)", rate)
            case .NGA_Regional : return "Regional(NGA)(" + String(format: "$%0.1f/hr)", rate)
            case .NGA_National : return "National(NGA)(" + String(format: "$%0.1f/hr)", rate)
            case .NGA_Elite : return "Elite(NGA)(" + String(format: "$%0.1f/hr)", rate)
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
                case .NGA_Local : return 23.0
                case .NGA_State : return 27.0
                case .NGA_Regional : return 31.0
                case .NGA_National : return 34.0
                case .NGA_Elite : return 37.0
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
            case Level.NGA_Local.description : return .NGA_Local
            case Level.NGA_State.description : return .NGA_State
            case Level.NGA_Regional.description : return .NGA_Regional
            case Level.NGA_National.description : return .NGA_National
            case Level.NGA_Elite.description : return .NGA_Elite
            
            case Level.FourToFive.fullDescription : return .FourToFive
            case Level.SixToEight.fullDescription : return .SixToEight
            case Level.FourToEight.fullDescription : return .FourToEight
            case Level.Nine.fullDescription : return .Nine
            case Level.Ten.fullDescription : return .Ten
            case Level.National.fullDescription : return .National
            case Level.Brevet.fullDescription : return .Brevet
            case Level.NGA_Local.fullDescription : return .NGA_Local
            case Level.NGA_State.fullDescription : return .NGA_State
            case Level.NGA_Regional.fullDescription : return .NGA_Regional
            case Level.NGA_National.fullDescription : return .NGA_National
            case Level.NGA_Elite.fullDescription : return .NGA_Elite
            default : return nil
            }
        }
        
        static var count: Int { return Level.NGA_Elite.rawValue + 1}
    }
    
    // MARK: Properties
    var name : String
    var level : Level
    var expenses : Array<Expense>
    var fees : Array<Fee>
    private var notes : String?
    private var paid : Bool?
    private var meetReferee : Bool?
    private var w9Received : Bool?
    private var receiptsReceived : Bool?
    private var meetRefereeFee : Float?
    
    
    //MARK: Initialization
    init(name: String, level: Level, expenses: Array<Expense>, fees: Array<Fee>, notes: String, paid: Bool, meetRef: Bool, w9Received : Bool, meetRefereeFee : Float, receiptsReceived: Bool) {
        // Initialize stored properties.
        
        self.name = name
        self.level = level
        self.expenses = expenses
        self.fees = fees
        self.notes = notes
        self.paid = paid
        self.meetReferee = meetRef
        self.w9Received = w9Received
        self.meetRefereeFee = meetRefereeFee
        self.receiptsReceived = receiptsReceived
    }
    
    required convenience init(name: String, level: Level, expenses: Array<Expense>, fees: Array<Fee>) {
        self.init(name: name, level: level, expenses: expenses, fees: fees, notes: "", paid: false, meetRef: false, w9Received: false, meetRefereeFee: 0.0, receiptsReceived: false)
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
            Expense(type: .Lodging, date: expenseDate),
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
        
        if isMeetRef(){
            totalFees += getMeetRefereeFee()
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
    
    func isMeetRef() -> Bool{
        return meetReferee ?? false
    }
    
    func setMeetRef(_ isMeetRef : Bool){
        self.meetReferee = isMeetRef
    }
    
    func isW9Received() -> Bool{
        return w9Received ?? false
    }
    
    func setW9Received(_ isW9Received : Bool){
        self.w9Received = isW9Received
    }
    
    func getMeetRefereeFee() -> Float{
        return meetRefereeFee ?? 0.0
    }
    
    func setMeetRefereeFee(_ amount : Float){
        self.meetRefereeFee = amount
    }
    
    func isReceiptsReceived() -> Bool{
        return receiptsReceived ?? false
    }
    
    func setReceiptsReceived(_ received : Bool){
        self.receiptsReceived = received
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
