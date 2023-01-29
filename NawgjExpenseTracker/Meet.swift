//
//  Meet.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/22/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class Meet: Codable {
    
    static let FED_MILEAGE_RATES : [Int: Float] = [2016 : 0.54, 2017 : 0.535, 2018 : 0.545, 2019 : 0.58, 2020 : 0.575, 2021 : 0.56, 2022 : 0.625, 2023 : 0.655]
    
    static func getMileageRate(forDate: Date) -> Float {
        let yearComponent = Calendar.current.component(.year, from: forDate)
        
        if let rate = Meet.FED_MILEAGE_RATES[yearComponent]{
            return rate
        }
        else{
            return Meet.FED_MILEAGE_RATES.sorted(by: {$0.key > $1.key}).first?.value ?? 0.57
        }
    }
    
    //MARK: Properties
    var name: String            // Identifies the name of the meet
    var days: Array<MeetDay>    // The specific meet days; 1 or more days
    var judges: Array<Judge>    // The Judges that worked at the meet
    var startDate: Date         // The first day of the meet
    var meetDescription: String // The levels competing at this meet or some meaningful description
    var location: String        // The location of the meet
        
    //MARK: Initialization
    init?(name: String, days: Array<MeetDay>, judges: Array<Judge>, startDate: Date, meetDescription: String?, location: String?) {
        // Initialization should fail if there is an empty name
        guard !name.isEmpty else {
            return nil
        }
        
        if meetDescription == nil{
            _ = " "
        }
        
        if location == nil{
            _ = " "
        }
        
        // Initialize stored properties.
        self.name = name
        self.days = days
        self.judges = judges
        self.startDate = startDate
        self.meetDescription = meetDescription!
        self.location = location!
    }
    
    required convenience init?(name: String, startDate: Date) {
        self.init(name: name, days: Array<MeetDay>(), judges: Array<Judge>(), startDate: startDate, meetDescription: " ", location: " ")
    }
    
    func getMileageRate() -> Float{
        return Meet.getMileageRate(forDate: startDate)
    }
    
    //MARK: Meet management and interogation
    func totalCostOfMeet() -> Float {
        var totalCost : Float = 0.0
        
        for judge in self.judges {
            totalCost += judge.totalCost()
        }
        
        return totalCost
    }
    
    func totalMeetHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalTimeInHours()
        }
        
        return totalHours
    }
    
    func billableMeetHours() -> Float {
        var totalHours : Float = 0.0
        
        for day in self.days {
            totalHours += day.totalBillableTimeInHours()
        }
        
        return totalHours
    }
    
    func addMeetDay(day: MeetDay) {
        self.days.append(day)
        // add fees to judges for this day
        for judge in self.judges {
            judge.fees.append(Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID())!)
        }
    }
    
    func addJudge(judge : Judge){
        
        for day in self.days{
            let fee = Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: judge.level.rate, notes: "", meetDayUUID: day.getUUID())
            judge.fees.append(fee!)
        }
        
        self.judges.append(judge)
    }
    
    func meetDayChanged(atIndex: Int){
        let meetDay = days[atIndex]
        for judge in judges{
            if let fee = judge.fees.first(where: { $0.getMeetDayUUID() == meetDay.getUUID() }) {
                if !fee.exclude! && !fee.hoursOverridden{
                    fee.hours = meetDay.totalBillableTimeInHours()
                    fee.date = meetDay.meetDate
                }
            }
        }
    }
    
    func removeMeetDay(at: Int) {
        let uuid = self.days[at].getUUID()
        
        for judge in self.judges {
            var idx : Int? = nil
            for (index, fee) in judge.fees.enumerated() {
                if fee.getMeetDayUUID() == uuid {
                    idx = index
                }
            }
            if idx != nil {
                judge.fees.remove(at: idx!)
            }
        }
        
        self.days.remove(at: at)
    }
    
    func removeJudgeAt(index: Int) {
        self.judges.remove(at: index)
    }
    
    func totalJudgeFeesAndExpenses() -> Float{
        var total : Float = 0.0
        
        for judge in self.judges {
            total += judge.totalCost()
        }
        
        return total
    }
    
    func totalJudgeFees() -> Float{
        var total : Float = 0.0
        
        for judge in self.judges {
            total += judge.totalFees()
        }
        
        return total
    }
    
    func judgesFeeForDay(dayIndex: Int, judge: Judge) -> Float{
        let date = days[dayIndex].meetDate
        if let fee = judge.fees.first(where: { $0.date == date}){
            return fee.getFeeTotal()
        }
        else{
            return 0.0
        }
    }
    
    func totalJudgesFeeForDay(dayIndex: Int) -> Float{
        var total : Float = 0.0
        for judge in judges{
            total += judgesFeeForDay(dayIndex: dayIndex, judge: judge)
        }
        
        return total
    }
    
    func totalBillableJudgeHours() -> Float{
        var total : Float = 0.0
        for judge in judges{
            total += judge.totalBillableHours()
        }
        
        return total
    }
}
