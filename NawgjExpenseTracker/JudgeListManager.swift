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
    
    func loadJudges(){
        do{
            let data:Data = try Data(contentsOf: JudgeListManager.ArchiveURL)
            let jsonDecoder = JSONDecoder()
            judges = try! jsonDecoder.decode([JudgeInfo].self, from: data) as [JudgeInfo]
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

    func addJudge(_ judgeInfo: JudgeInfo){
        judges?.append(judgeInfo)
        saveJudges()
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
    
    func updateSelectedJudgeWith(_ judgeInfo : JudgeInfo){
        if let index = selectedJudgeIndex, var judges = judges{
            judges[index] = judgeInfo
            selectedJudge = judgeInfo
            saveJudges()
        }
    }
}
