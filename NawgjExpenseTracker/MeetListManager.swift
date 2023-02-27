//
//  MeetListManager.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import os.log
import UIKit

class MeetListManager{
    
    private static var instance : MeetListManager?
    
    static func GetInstance() -> MeetListManager{
        if instance == nil{
            instance = MeetListManager()
        }
        
        return instance!
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("Meets")
    
    var meets : [Meet]?
    
    var selectedMeetIndex : Int?
    var selectedMeetDayIndex : Int?
    var selectedJudgeIndex : Int?
    var selectedExpenseIndex : Int?
    var selectedFeeIndex : Int?
    
    func loadMeets(){
        do{
            let data:Data = try Data(contentsOf: MeetListManager.ArchiveURL)
            let jsonDecoder = JSONDecoder()
            meets = try jsonDecoder.decode([Meet].self, from: data) as [Meet]
        } catch{
            os_log("Failed to load meets...", log: OSLog.default, type: .error)
            meets = Array<Meet>()
        }
        
        
        if let meets = meets{
            for meet in meets{
                // Make sure all meet days have uuid strings associated with them
                // Touch the UUID attribute to ensure that one is created
                for meetDay in meet.days{
                    _ = meetDay.getUUID()
                }
                
                // Make sure all the judge fees have a meet day UUID associated with them
                // by adding a meet day uuid to fees that don't have them. The matchup uses
                // the date. If a fee uuid already exists then skip that fee
                for judge in meet.judges{
                    var feesToDelete = Array<String>()
                    for fee in judge.fees{
                        if fee.getMeetDayUUID() == nil{
                            // Find the meet day matching this fee (if none found, remove this fee)
                            if let meetDay = meet.days.first(where: {$0.meetDate == fee.date}){
                                fee.setMeetDayUUID(uuid: meetDay.getUUID())
                            }
                            else{
                                let uuidString = UUID.init().uuidString
                                feesToDelete.append(uuidString)
                                fee.setMeetDayUUID(uuid: uuidString)
                            }
                        }
                    }
                    
                    // Remove any fees that don't have a corresponding date
                    if feesToDelete.count > 0{
                        for feeToDelete in feesToDelete{
                            if let index = judge.fees.firstIndex(where: {$0.getMeetDayUUID() == feeToDelete}){
                                judge.fees.remove(at: index)
                            }
                        }
                    }
                    
                    // Run through the list and find any meet days without a corresponding fee for it in the judges
                    // fee list and add a fee entry
                    for meetDay in meet.days{
                        if !judge.fees.contains(where: {$0.getMeetDayUUID() == meetDay.getUUID()}){
                            // Add a new fee to the judges fees list corresponding to this day
                            if let fee = Fee(date: meetDay.meetDate, hours: meetDay.totalBillableTimeInHours(), rate: judge.level.rate, notes: nil, meetDayUUID: meetDay.getUUID()){
                                judge.fees.append(fee)
                            }
                        }
                    }
                }
            }
        }
        
        saveMeets()
    }
    
    func saveMeets(){
        if meets != nil{
            do{
                let encodedData = try JSONEncoder().encode(meets)
                try encodedData.write(to: MeetListManager.ArchiveURL)
            } catch{
                os_log("Failed to save meets...", log: OSLog.default, type: .error)
            }
        }else{
            os_log("Couldn't save meets - No meets are loaded", log: OSLog.default, type: .error)
        }
    }
    
    func addMeet(meet : Meet){
        if meets != nil{
            meets!.append(meet)
            saveMeets()
        }
    }
    
    func addJudge(judge : Judge){
        if let meet = getSelectedMeet(){
            meet.addJudge(judge: judge)
            saveMeets()
        }
    }
    
    func addMeetDay(meetDay : MeetDay){
        if let meet = getSelectedMeet(){
            meet.addMeetDay(day: meetDay)
            meet.days = meet.days.sorted(by: {$0.meetDate < $1.meetDate})
            saveMeets()
        }
    }
    
    func updateSelectedMeetWith(meet : Meet){
        if meets != nil, let index = selectedMeetIndex, index < meets!.count{
            meets![index] = meet
            saveMeets()
        }
    }
    
    func updateSelectedMeetDayWith(meetDay : MeetDay){
        if let meet = getSelectedMeet(), let meetDayIndex = selectedMeetDayIndex{
            meet.days[meetDayIndex] = meetDay
            meet.meetDayChanged(atIndex: meetDayIndex)
            meet.days = meet.days.sorted(by: {$0.meetDate < $1.meetDate})
            saveMeets()
        }
    }
    
    func updateSelectedJudgeWith(judge : Judge){
        if let meet = getSelectedMeet(), let judgeIndex = selectedJudgeIndex{
            meet.judges[judgeIndex] = judge
            saveMeets()
        }
    }
    
    func updateSelectedFeeWith(fee : Fee){
        if let fee = getSelectedFee(), let judge = getSelectedJudge(), let index = selectedFeeIndex {
            judge.fees[index] = fee
            saveMeets()
        }
    }
    
    func updateSelectedExpenseWith(expense : Expense){
        if let expense = getSelectedExpense(), let judge = getSelectedJudge(), let index = selectedExpenseIndex {
            judge.expenses[index] = expense
            saveMeets()
        }
    }
    
    func removeMeetAt(index: Int){
        if meets != nil{
            if meets!.count > index{
                meets?.remove(at: index)
            }
            saveMeets()
        }
    }
    
    func removeMeetDayAt(index: Int){
        if let meet = getSelectedMeet(){
            meet.removeMeetDay(at: index)
            meet.days = meet.days.sorted(by: {$0.meetDate < $1.meetDate})
            saveMeets()
        }
    }
    
    func removeJudgeAt(index: Int){
        if let meet = getSelectedMeet(){
            meet.removeJudgeAt(index: index)
            saveMeets()
        }
    }
    
    func selectMeetAt(index : Int){
        selectedMeetIndex = index
    }
    
    func selectJudgeAt(index : Int){
        selectedJudgeIndex = index
    }
    
    func selectExpenseAt(index : Int){
        selectedExpenseIndex = index
    }
    
    func selectFeeAt(index : Int){
        selectedFeeIndex = index
    }
    
    func selectMeetDayAt(index : Int){
        selectedMeetDayIndex = index
    }
    
    func selectMeetDayForFee(fee : Fee){
        if let meet = getSelectedMeet(){
            if let index = meet.days.firstIndex(where: { $0.meetDate == fee.date}){
                selectMeetDayAt(index: index)
            }
        }
    }
    
    func getSelectedMeet() -> Meet?{
        if let allMeets = meets, let index = selectedMeetIndex{
            return allMeets[index]
        }
        return nil
    }
    
    func getSelectedJudge() -> Judge?{
        if let selectedMeet = getSelectedMeet(), let index = selectedJudgeIndex{
            return selectedMeet.judges[index]
        }
        return nil
    }
    
    func getSelectedMeetDay() -> MeetDay?{
        if let selectedMeet = getSelectedMeet(), let index = selectedMeetDayIndex{
            return selectedMeet.days[index]
        }
        return nil
    }
    
    func getSelectedExpense() -> Expense?{
        if let selectedJudge = getSelectedJudge(), let index = selectedExpenseIndex{
            return selectedJudge.expenses[index]
        }
        return nil
    }
    
    func getSelectedFee() -> Fee?{
        if let selectedJudge = getSelectedJudge(), let index = selectedFeeIndex{
            return selectedJudge.fees[index]
        }
        return nil
    }
    
    func moveMeet(fromIndex: Int, toIndex: Int){
        let meet = meets?.remove(at: fromIndex)
        meets?.insert(meet!, at: toIndex)
        saveMeets()
    }
    
    func importMeet(fromFile: URL?){
        if let jsonFile = fromFile{
            do{
                let data:Data = try Data(contentsOf: jsonFile)
                let jsonDecoder = JSONDecoder()
                let importedMeet = try jsonDecoder.decode(Meet.self, from: data) as Meet
                
                addMeet(meet: importedMeet)
            }
            catch{
                os_log("Failed to import meet...", log: OSLog.default, type: .error)
            }
        }
    }
}
