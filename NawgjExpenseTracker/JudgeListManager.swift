//
//  JudgeListManager.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/21/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import os.log
import UIKit

class JudgeListManager{
    
    private static var instance : JudgeListManager?
    
    static func GetInstance() -> JudgeListManager{
        if instance == nil{
            instance = JudgeListManager()
        }
        
        return instance!
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("Judges")
    
    var judges : [JudgeInfo]?
    var selectedJudge : JudgeInfo?
    var selectedJudgeIndex : Int?

    /// Chains successive `saveJudges()` calls so their underlying async
    /// disk writes complete in the same order they were requested, even
    /// though each call returns immediately without blocking the caller.
    private var pendingSaveTask: Task<Void, Never>?
    
    func loadAndSortJudges(){
        self.loadJudges()
        if let originalJudgeList = judges{
            judges = originalJudgeList.sorted(by: {$0.name < $1.name})
        }
    }

    /// Async equivalent of `loadAndSortJudges()`, for adoption by newer
    /// (e.g. SwiftUI) call sites that can `await` the result instead of
    /// relying on `judges` being populated synchronously.
    func loadAndSortJudgesAsync() async -> [JudgeInfo] {
        let loadedJudges = await loadJudgesAsync()
        let sorted = loadedJudges.sorted(by: {$0.name < $1.name})
        judges = sorted
        return sorted
    }
    
    func importJudges(fromFile: URL?){
        if let jsonFile = fromFile{
            guard jsonFile.startAccessingSecurityScopedResource() else {
                os_log("Failed permission to access judge data...", log: OSLog.default, type: .error)
                return
            }
            defer { jsonFile.stopAccessingSecurityScopedResource() }
            do {
                let data:Data = try Data(contentsOf: jsonFile)
                let jsonDecoder = JSONDecoder()
                let importedJudges = try jsonDecoder.decode([JudgeInfo].self, from: data) as [JudgeInfo]
                
                for judge in importedJudges{
                    _ = judge.getUUID() // Touch each Judge's uuid to make sure one has been created
                    let judgeInfo = JudgeInfo(name: judge.name, level: judge.level)
                    if JudgeListManager.GetInstance().addJudge(judgeInfo){
                        os_log("Added Judge %@", log: OSLog.default, type: .debug, judgeInfo.name)
                    } else{
                        os_log("Judge %@ not added because they already exist in the Judge List", log: OSLog.default, type: .debug, judgeInfo.name)
                    }
                }
                
                saveJudges()
                loadAndSortJudges()
            }
            catch {
                os_log("Failed to import judges...", log: OSLog.default, type: .error)
            }
        }
    }
    
    func loadJudges(){
        do{
            let data:Data = try Data(contentsOf: JudgeListManager.ArchiveURL)
            judges = try JudgeListManager.decodeJudges(from: data)
            saveJudges()
        } catch{
            os_log("Failed to load judges...", log: OSLog.default, type: .error)
            judges = Array<JudgeInfo>()
        }
    }

    /// Async equivalent of `loadJudges()`. Does not mutate `judges` directly -
    /// callers decide when/whether to assign the result.
    func loadJudgesAsync() async -> [JudgeInfo] {
        do {
            let data = try Data(contentsOf: JudgeListManager.ArchiveURL)
            let loadedJudges = try JudgeListManager.decodeJudges(from: data)
            await saveJudgesAsync(loadedJudges)
            return loadedJudges
        } catch {
            os_log("Failed to load judges...", log: OSLog.default, type: .error)
            return []
        }
    }

    private static func decodeJudges(from data: Data) throws -> [JudgeInfo] {
        let decoded = try JSONDecoder().decode([JudgeInfo].self, from: data)
        for judge in decoded{
            _ = judge.getUUID() // Touch each Judge's uuid to make sure one has been created
        }
        return decoded
    }
    
    /// Fire-and-forget save used by existing (synchronous) call sites. The
    /// actual encode + disk write happens off the calling thread via
    /// `saveJudgesAsync(_:)`, chained after any already-pending save so
    /// writes are never applied out of order.
    func saveJudges(){
        guard let judges = judges else {
            os_log("Couldn't save judges - No judges are loaded", log: OSLog.default, type: .error)
            return
        }
        let previousTask = pendingSaveTask
        pendingSaveTask = Task {
            _ = await previousTask?.value
            await JudgeListManager.writeJudges(judges)
        }
    }

    /// Async equivalent of `saveJudges()` for callers that want to `await`
    /// completion of the disk write (e.g. before dismissing a screen).
    @discardableResult
    func saveJudgesAsync(_ judgesToSave: [JudgeInfo]? = nil) async -> Bool {
        guard let judges = judgesToSave ?? judges else {
            os_log("Couldn't save judges - No judges are loaded", log: OSLog.default, type: .error)
            return false
        }
        await JudgeListManager.writeJudges(judges)
        return true
    }

    private static func writeJudges(_ judges: [JudgeInfo]) async {
        do{
            let encodedData = try JSONEncoder().encode(judges)
            try encodedData.write(to: JudgeListManager.ArchiveURL, options: .atomic)
        } catch{
            os_log("Failed to save judges...", log: OSLog.default, type: .error)
        }
    }

    func addJudge(_ judgeInfo: JudgeInfo) -> Bool {
        var judgeAdded = false
        if self.indexOfJudge(judgeInfo) < 0{
            judges?.append(judgeInfo)
            saveJudges()
            judgeAdded = true
        }
        return judgeAdded
    }
    
    func removeJudgeAt(_ index: Int){
        judges?.remove(at: index)
        saveJudges()
    }
    
    func selectJudgeInfoAt(_ index : Int){
        if let judges = judges{
            selectedJudgeIndex = index
            selectedJudge = judges[index]
        }
    }
    
    func judgeInfo(forJudgeID: String) -> String?{
        if let judgeList = judges{
            if let judge = judgeList.first(where: {$0.getUUID() == forJudgeID}){
                return judge.getUUID()
            }
        }
        return nil
    }
    
    func updateSelectedJudgeWith(_ judgeInfo : JudgeInfo){
        if let index = selectedJudgeIndex, let judges = judges{
            judges[index].name = judgeInfo.name
            judges[index].level = judgeInfo.level
            selectedJudge = judges[index]
            saveJudges()
        }
    }
    
    /// Return the index of the judge that matches the judge info criteria provide.
    /// Case insensitive and level must match
    ///
    func indexOfJudge(_ judgeInfo : JudgeInfo) -> Int{
        if let judgeList = judges{
            return judgeList.firstIndex(where: {$0.name.lowercased() == judgeInfo.name.lowercased() && $0.level == judgeInfo.level}) ?? -1
        } else{
            return -1
        }
    }
}
