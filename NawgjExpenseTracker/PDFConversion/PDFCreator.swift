//
//  PDFCreator.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 2/9/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import PDFKit
import UIKit

class PDFCreator{
    static var dateFormatter : DateFormatter = DateFormatter()
    static var dateFormatterMedium : DateFormatter = DateFormatter()
    static var dateFormatterShort : DateFormatter = DateFormatter()
    static var timeFormatter : DateFormatter = DateFormatter()
    
    static var numberFormatter : NumberFormatter = NumberFormatter()
}
