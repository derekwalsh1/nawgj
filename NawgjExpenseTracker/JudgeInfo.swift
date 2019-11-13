//
//  JudgeInfo.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/21/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeInfo: Codable {
    
    // MARK: Properties
    var name : String
    var level : Judge.Level
    private var uuid : String?
    
    //MARK: Initialization
    init(name: String, level: Judge.Level, uuid: String){
        self.name = name
        self.level = level
        self.uuid = uuid
    }
    
    required convenience init(name: String, level: Judge.Level){
        self.init(name: name, level: level, uuid: UUID.init().uuidString)
    }
    
    func setUUID(_ uuid: String){
        self.uuid = uuid
    }
    
    func getUUID() -> String{
        if uuid == nil{
            uuid = UUID.init().uuidString
        }
        
        return uuid!
    }
}
