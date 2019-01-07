//
//  MeetPDFCreator.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/30/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import PDFKit
import UIKit

class MeetPDFCreator{
    
    static func createPDFFromView(meet: Meet, atLocation: URL){
        
        
        let html = """
        <html>
        <head>
        </head>
        <body>
        <p align="right">
            <font size="16">
                <b>MEET REPORT</b>
            </font>
        </p>
        <p align="left">
        <table width="300" border="1" cellspacing="3" cellpadding="2">
            <tr><td>
            Meet Name: \(meet.name)
            </td></tr>
            <tr><td>
            Meet Location: \(meet.location)
            </td></tr>
            <tr><td>
            Meet Details: \(meet.meetDescription)
            </td></tr>
        </table>
        </p>
        <b>Hello <i>World!</i></b>
        </body>
        </html>
        """
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        
        // 3. Assign paperRect and printableRect
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        
        
        for i in 0..<render.numberOfPages{
            UIGraphicsBeginPDFPage();
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        /*UIGraphicsBeginPDFContextToFile(atLocation, view.bounds, nil)
        UIGraphicsBeginPDFPage()
        guard let pdfContext = UIGraphicsGetCurrentContext() else {
            return
        }
        
        
        view.layer.render(in: pdfContext)*/
        UIGraphicsEndPDFContext()
        pdfData.write(to: atLocation, atomically: true)
    }
}
