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
    
    //MARK: Initialization
    init(name: String, level: Judge.Level){
        self.name = name
        self.level = level
    }
}
