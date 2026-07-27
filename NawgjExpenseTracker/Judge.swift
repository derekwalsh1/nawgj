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
        // MARK: Legacy levels (retained for backward compatibility only)
        // These raw values and rates must never change - existing judges and meets
        // already saved with these levels rely on them decoding to the same rate.
        // They are intentionally excluded from `selectableCases` so they can no
        // longer be chosen when adding or editing a judge.
        case FourToFive = 0
        case SixToEight = 1
        case FourToEight = 2
        case Nine = 3
        case Ten = 4
        case National = 5
        case Brevet = 6

        // MARK: NGA levels (unchanged)
        case NGA_Local = 7
        case NGA_State = 8
        case NGA_Regional = 9
        case NGA_National = 10
        case NGA_Elite = 11

        // MARK: Current (selectable) non-NGA levels
        case FourFiveX1R = 12
        case SixSeven = 13
        case EightXR = 14
        case LevelNine = 15
        case LevelTen = 16
        case N4 = 17
        case N3 = 18
        case B2N2 = 19
        case B1N1 = 20
        
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
                case .FourFiveX1R : return "Levels 4, 5 and X1R"
                case .SixSeven : return "Levels 6 and 7"
                case .EightXR : return "Level 8 and XR"
                case .LevelNine : return "Level 9"
                case .LevelTen : return "Level 10"
                case .N4 : return "N4"
                case .N3 : return "N3"
                case .B2N2 : return "B2/N2"
                case .B1N1 : return "B1/N1"
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
            case .FourFiveX1R : return "Levels 4, 5 and X1R (" + String(format: "$%0.1f/hr)", rate)
            case .SixSeven : return "Levels 6 and 7 (" + String(format: "$%0.1f/hr)", rate)
            case .EightXR : return "Level 8 and XR (" + String(format: "$%0.1f/hr)", rate)
            case .LevelNine : return "Level 9 (" + String(format: "$%0.1f/hr)", rate)
            case .LevelTen : return "Level 10 (" + String(format: "$%0.1f/hr)", rate)
            case .N4 : return "N4 (" + String(format: "$%0.1f/hr)", rate)
            case .N3 : return "N3 (" + String(format: "$%0.1f/hr)", rate)
            case .B2N2 : return "B2/N2 (" + String(format: "$%0.1f/hr)", rate)
            case .B1N1 : return "B1/N1 (" + String(format: "$%0.1f/hr)", rate)
            }
        }
        
        var rate: Float {
            switch self {
                case .FourToFive : return 19.0
                case .SixToEight : return 21.0
                case .FourToEight : return 23.0
                case .Nine : return 27.0
                case .Ten : return 31.0
                case .National : return 34.0
                case .Brevet : return 37.0
                case .NGA_Local : return 23.0
                case .NGA_State : return 27.0
                case .NGA_Regional : return 31.0
                case .NGA_National : return 34.0
                case .NGA_Elite : return 37.0
                case .FourFiveX1R : return 20.0
                case .SixSeven : return 21.0
                case .EightXR : return 24.0
                case .LevelNine : return 28.0
                case .LevelTen : return 32.0
                case .N4 : return 34.0
                case .N3 : return 36.0
                case .B2N2 : return 38.0
                case .B1N1 : return 40.0
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
            case Level.FourFiveX1R.description : return .FourFiveX1R
            case Level.SixSeven.description : return .SixSeven
            case Level.EightXR.description : return .EightXR
            case Level.LevelNine.description : return .LevelNine
            case Level.LevelTen.description : return .LevelTen
            case Level.N4.description : return .N4
            case Level.N3.description : return .N3
            case Level.B2N2.description : return .B2N2
            case Level.B1N1.description : return .B1N1
            
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
            case Level.FourFiveX1R.fullDescription : return .FourFiveX1R
            case Level.SixSeven.fullDescription : return .SixSeven
            case Level.EightXR.fullDescription : return .EightXR
            case Level.LevelNine.fullDescription : return .LevelNine
            case Level.LevelTen.fullDescription : return .LevelTen
            case Level.N4.fullDescription : return .N4
            case Level.N3.fullDescription : return .N3
            case Level.B2N2.fullDescription : return .B2N2
            case Level.B1N1.fullDescription : return .B1N1
            default : return nil
            }
        }
        
        static var count: Int { return Level.B1N1.rawValue + 1}
        
        /// The levels that can be chosen when adding or editing a judge.
        /// Legacy levels are intentionally omitted here (but remain valid,
        /// decodable `Level` values) so existing judges/meets keep displaying
        /// and billing at their original rate until explicitly changed.
        static let selectableCases: [Level] = [
            .FourFiveX1R, .SixSeven, .EightXR, .LevelNine, .LevelTen, .N4, .N3, .B2N2, .B1N1,
            .NGA_Local, .NGA_State, .NGA_Regional, .NGA_National, .NGA_Elite
        ]
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
            // Fees with a manually-overridden rate keep that rate across
            // level changes - only non-overridden fees track the judge's
            // level rate.
            if !fee.rateOverridden {
                fee.rate = self.level.rate
            }
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
        // A day can now have multiple sessions (and therefore multiple fees
        // sharing the same date), so sum every matching fee rather than
        // taking just the first one.
        return fees.filter { $0.date == date }.reduce(0) { $0 + $1.getFeeTotal() }
    }
}
