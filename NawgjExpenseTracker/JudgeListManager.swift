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
    
    func loadAndSortJudges(){
        self.loadJudges()
        if let originalJudgeList = judges{
            judges = originalJudgeList.sorted(by: {$0.name < $1.name})
        }
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
            let jsonDecoder = JSONDecoder()
            judges = try jsonDecoder.decode([JudgeInfo].self, from: data) as [JudgeInfo]
            
            if let judgeList = judges{
                for judge in judgeList{
                    _ = judge.getUUID() // Touch each Judge's uuid to make sure one has been created
                }
            }
            
            saveJudges()
        } catch{
            os_log("Failed to load judges...", log: OSLog.default, type: .error)
            judges = Array<JudgeInfo>()
        }
    }
    
    func saveJudges(){
        if let judges = judges{
            do{
                let encodedData = try JSONEncoder().encode(judges)
                try encodedData.write(to: JudgeListManager.ArchiveURL)
            } catch{
                os_log("Failed to save judges...", log: OSLog.default, type: .error)
            }
        }else{
            os_log("Couldn't save judges - No judges are loaded", log: OSLog.default, type: .error)
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
    
    func indexOfJudge(_ judgeInfo : JudgeInfo) -> Int{
        if let judgeList = judges{
            return judgeList.firstIndex(where: {$0.name == judgeInfo.name}) ?? -1
        } else{
            return -1
        }
    }
}
