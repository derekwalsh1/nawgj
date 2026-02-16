//
//  MeetUIPrintPageRender.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit

class MeetUIPrintPageRender : UIPrintPageRenderer{
    
    var date : Date
    var meetName : String
    var dateFormatter : DateFormatter = DateFormatter()
    
    init(date: Date, meetName: String){
        
        self.date = date
        self.meetName = meetName
        self.dateFormatter.dateStyle = .short
        
        super.init()
    }
    
    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect){
        let footerText = "\(meetName) | Report Date: \(dateFormatter.string(from: date)) | Page \(pageIndex + 1) of \(self.numberOfPages)"

        let font = UIFont.preferredFont(forTextStyle: .footnote)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        let nsFooter = NSString(string: footerText)
        let horizontalPadding: CGFloat = 8.0
        let maxWidth = max(0, footerRect.width - horizontalPadding * 2)

        let bounding = nsFooter.boundingRect(with: CGSize(width: maxWidth, height: footerRect.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)

        let drawWidth = min(ceil(bounding.width), maxWidth)
        let drawHeight = ceil(bounding.height)

        let drawX = footerRect.midX - drawWidth / 2.0
        let drawY = footerRect.midY - drawHeight / 2.0

        let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        nsFooter.draw(in: drawRect, withAttributes: attributes)
    }
}
