//
//  MeetUIPrintPageRender.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit

class JudgeUIPrintPageRender : UIPrintPageRenderer{
    
    var date : Date
    var judge : Judge
    var meetName : String
    var dateFormatter : DateFormatter = DateFormatter()
    
    init(date: Date, judge: Judge, name: String){
        
        self.date = date
        self.judge = judge
        self.meetName = name
        self.dateFormatter.dateStyle = .short
        
        super.init()
    }
    
    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect){
        let footerText = "\(judge.name) | Meet: \(meetName) | Report Date: \(dateFormatter.string(from: date)) | Page \(pageIndex + 1) of \(self.numberOfPages)"
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let size = (footerText as NSString?)!.size(withAttributes: [NSAttributedString.Key.font: font])
        
        let drawX = footerRect.maxX / 2 - size.width/2
        let drawY = footerRect.maxY - size.height - 20
        
        let drawPoint = CGPoint(x: drawX, y: drawY)
        (footerText as NSString?)?.draw(at: drawPoint, withAttributes: [NSAttributedString.Key.font: font])
    }
}
