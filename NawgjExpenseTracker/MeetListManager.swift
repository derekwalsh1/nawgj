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
            meets = try! jsonDecoder.decode([Meet].self, from: data) as [Meet]
        } catch{
            os_log("Failed to load meets...", log: OSLog.default, type: .error)
            meets = Array<Meet>()
        }
        //meets!.sort(by: {$0.startDate > $1.startDate})
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
            if let index = meet.days.index(where: { $0.meetDate == fee.date}){
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
}
