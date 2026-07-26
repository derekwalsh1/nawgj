//
//  MeetListManager.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import os.log
import UIKit

/// Protocol abstraction over `MeetListManager`'s public API so consumers
/// (views, view controllers) can depend on an interface rather than the
/// concrete singleton, and so tests can inject a mock implementation via
/// `MeetListManager.setInstanceForTesting(_:)`.
protocol MeetListManaging: AnyObject {
    var meets: [Meet]? { get set }
    var selectedMeetIndex: Int? { get set }
    var selectedMeetDayIndex: Int? { get set }
    var selectedJudgeIndex: Int? { get set }
    var selectedExpenseIndex: Int? { get set }
    var selectedFeeIndex: Int? { get set }

    func loadMeets()
    func loadMeetsAsync() async -> [Meet]
    func saveMeets()
    @discardableResult
    func saveMeetsAsync(_ meetsToSave: [Meet]?) async -> Bool
    func addMeet(meet: Meet)
    func addJudge(judge: Judge)
    func addMeetDay(meetDay: MeetDay)
    func updateSelectedMeetWith(meet: Meet)
    func updateSelectedMeetDayWith(meetDay: MeetDay)
    func updateSelectedJudgeWith(judge: Judge)
    func updateSelectedFeeWith(fee: Fee)
    func updateSelectedExpenseWith(expense: Expense)
    func removeMeetAt(index: Int)
    func removeMeetDayAt(index: Int)
    func removeJudgeAt(index: Int)
    func selectMeetAt(index: Int)
    func selectJudgeAt(index: Int)
    func selectExpenseAt(index: Int)
    func selectFeeAt(index: Int)
    func selectMeetDayAt(index: Int)
    func selectMeetDayForFee(fee: Fee)
    func getSelectedMeet() -> Meet?
    func getSelectedJudge() -> Judge?
    func getSelectedMeetDay() -> MeetDay?
    func getSelectedExpense() -> Expense?
    func getSelectedFee() -> Fee?
    func moveMeet(fromIndex: Int, toIndex: Int)
    func importMeet(fromFile: URL?)
}

class MeetListManager: MeetListManaging {
    
    private static var instance : MeetListManaging?
    
    static func GetInstance() -> MeetListManaging{
        if instance == nil{
            instance = MeetListManager()
        }
        
        return instance!
    }

    /// Test-only seam: inject a mock/stub conforming to `MeetListManaging`
    /// so tests can exercise consumers without touching real disk state.
    /// Pass `nil` to reset back to the default concrete `MeetListManager`
    /// on the next `GetInstance()` call.
    static func setInstanceForTesting(_ mock: MeetListManaging?) {
        instance = mock
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("Meets")
    
    var meets : [Meet]?
    
    var selectedMeetIndex : Int?
    var selectedMeetDayIndex : Int?
    var selectedJudgeIndex : Int?
    var selectedExpenseIndex : Int?
    var selectedFeeIndex : Int?

    /// Chains successive `saveMeets()` calls so their underlying async disk
    /// writes complete in the same order they were requested, even though
    /// each call returns immediately without blocking the caller.
    private var pendingSaveTask: Task<Void, Never>?
    
    func loadMeets(){
        do{
            let data:Data = try Data(contentsOf: MeetListManager.ArchiveURL)
            meets = try MeetListManager.decodeAndNormalizeMeets(from: data)
        } catch{
            os_log("Failed to load meets...", log: OSLog.default, type: .error)
            meets = Array<Meet>()
        }
        
        saveMeets()
    }

    /// Async equivalent of `loadMeets()`. Does not mutate `meets` directly -
    /// callers decide when/whether to assign the result.
    func loadMeetsAsync() async -> [Meet] {
        let loadedMeets: [Meet]
        do {
            let data = try Data(contentsOf: MeetListManager.ArchiveURL)
            loadedMeets = try MeetListManager.decodeAndNormalizeMeets(from: data)
        } catch {
            os_log("Failed to load meets...", log: OSLog.default, type: .error)
            loadedMeets = []
        }
        await saveMeetsAsync(loadedMeets)
        return loadedMeets
    }

    /// Decodes the meets archive and runs the same meet-day/fee
    /// synchronization performed by `loadMeets()` (ensures every meet day
    /// and judge fee has a UUID, and that judges have a fee entry for every
    /// meet day). Shared by both the sync and async load paths.
    private static func decodeAndNormalizeMeets(from data: Data) throws -> [Meet] {
        let decodedMeets = try JSONDecoder().decode([Meet].self, from: data)

        for meet in decodedMeets{
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

        return decodedMeets
    }
    
    /// Fire-and-forget save used by existing (synchronous) call sites. The
    /// actual encode + disk write happens off the calling thread via
    /// `saveMeetsAsync(_:)`, chained after any already-pending save so
    /// writes are never applied out of order.
    func saveMeets(){
        guard let meets = meets else {
            os_log("Couldn't save meets - No meets are loaded", log: OSLog.default, type: .error)
            return
        }
        let previousTask = pendingSaveTask
        pendingSaveTask = Task {
            _ = await previousTask?.value
            await MeetListManager.writeMeets(meets)
        }
    }

    /// Async equivalent of `saveMeets()` for callers that want to `await`
    /// completion of the disk write (e.g. before dismissing a screen).
    @discardableResult
    func saveMeetsAsync(_ meetsToSave: [Meet]? = nil) async -> Bool {
        guard let meets = meetsToSave ?? meets else {
            os_log("Couldn't save meets - No meets are loaded", log: OSLog.default, type: .error)
            return false
        }
        await MeetListManager.writeMeets(meets)
        return true
    }

    private static func writeMeets(_ meets: [Meet]) async {
        do{
            let encodedData = try JSONEncoder().encode(meets)
            try encodedData.write(to: MeetListManager.ArchiveURL, options: .atomic)
        } catch{
            os_log("Failed to save meets...", log: OSLog.default, type: .error)
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
