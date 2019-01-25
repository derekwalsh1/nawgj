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
    static var dateFormatter : DateFormatter = DateFormatter()
    static var dateFormatterMedium : DateFormatter = DateFormatter()
    static var dateFormatterShort : DateFormatter = DateFormatter()
    
    static var numberFormatter : NumberFormatter = NumberFormatter()
    
    static func createPDFFrom(meet: Meet, atLocation: URL){
        
        dateFormatter.dateStyle = .full
        dateFormatterShort.dateStyle = .short
        dateFormatterMedium.dateStyle = .medium
        numberFormatter.numberStyle = .currency
        
        var html = generateHTMLHeader()
        html += generateMeetSummaryTable(meet: meet)
        html += generateFeeTable(meet: meet)
        html += generateFeeTableFooter(meet: meet)
        html += generateHTMLFooter()
        
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = MeetUIPrintPageRender(date: Date(), meetName: meet.name)
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        render.footerHeight = 10
        render.headerHeight = 10
        
        // 3. Assign paperRect and printableRect
        let page = CGRect(x: 20, y: 20, width: 595.2, height: 841.2) // A4, 72 dpi
        let printable = CGRect(x: 20, y: 20, width: 595.2, height: 841.2) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(printable, forKey: "printableRect")
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 620, height: 900), nil)
        
        for i in 0..<render.numberOfPages{
            UIGraphicsBeginPDFPage();
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            render.drawFooterForPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        UIGraphicsEndPDFContext()
   
        pdfData.write(to: atLocation, atomically: true)
        
    }
    
    static func generateHTMLHeader() -> String{
        return """
        <html>
            <head>
                <style type="text/css">
                @media print {
                .pagebreak-before:first-child { display: block; page-break-before: avoid; }
                .pagebreak-before { display: block; page-break-before: always; }
                }
                </style>
            </head>
        <body>
        """
    }
    
    static func generateHTMLFooter() -> String{
        return """
        </body>
        </html>
        """
    }
    
    static func generateMeetSummaryTable(meet: Meet) -> String{
        let sortedDays = meet.days.sorted(by: { $0.meetDate < $1.meetDate })
        var datesString = ""
        for (index, day) in sortedDays.enumerated(){
            datesString += "\(index == 0 ? "" : "<br>")\(dateFormatter.string(from: day.meetDate))"
        }
        
        let sortedJudges = meet.judges.sorted(by: { $0.name < $1.name })
        var judgeNames = ""
        for (index, judge) in sortedJudges.enumerated(){
            judgeNames += "\(index == 0 ? "" : "<br>")\(judge.name) - \(judge.level.fullDescription)"
        }
        
        let totalFeesString = numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!
        let totalHoursString = String(format: "%0.2f Hours", meet.totalMeetHours())
        
        return """
        <h1 class="pagebreak-before">Meet Summary : \(meet.name)</h1>
        <hr>
        <table cellpadding="5" cellspacing="0" border="0">
            <tr align="left">
                <th width="10">Meet Name</th>
                <td width="300">\(meet.name)</td>
            </tr>
            <tr align="left">
                <th>Date</th>
                <td>\(dateFormatter.string(from: meet.startDate))</td>
            </tr>
            <tr align="left">
                <th>Location</th>
                <td>\(meet.location)</td>
            </tr>
            <tr align="left">
                <th>Details/Description</th>
                <td>\(meet.meetDescription)</td>
            </tr>
            <tr align="left">
                <th valign="top">Meet Dates</th>
                <td>\(datesString)</td>
            </tr>
            <tr align="left">
                <th valign="top">Judges</th>
                <td>\(judgeNames)</td>
            </tr>
            <tr align="left">
                <th valign="top">Total Hours</th>
                <td>\(totalHoursString)</td>
            </tr>
            <tr align="left">
                <th valign="top">Total Billed Judge Hours</th>
                <td>\(String(format: "%0.2f Hours", meet.totalBillableJudgeHours()))</td>
            </tr>
            <tr align="left">
                <th valign="top">Total Fees</th>
                <td>\(totalFeesString)</td>
            </tr>
            <tr align="left">
                <th valign="top">Federal Mileage Rate</th>
                <td>\(String(format: "$%0.2f/mile", meet.getMileageRate()))</td>
            </tr>
        </table>
        
        
        
        """
    }
    
    static func generateFeeTable(meet: Meet) -> String{
        var htmlString : String = """

        <h1 class="pagebreak-before">Meet Fee Details</h1>
        <hr>
        <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr align="left" height="26">
            <th>Date</th>
            <th>Judge Name</th>
            <th>Rate</th>
            <th>Rate Code</th>
            <th>Hours</th>
            <th>Fee</th>
        </tr>
        """
        
        for (dayIndex, day) in meet.days.sorted(by: { $0.meetDate < $1.meetDate }).enumerated(){
            for (judgeIndex, judge) in meet.judges.sorted(by: { $0.name < $1.name }).enumerated(){
                if let fee = judge.fees.first(where: {$0.date == day.meetDate}){
                
                    htmlString += """
                    <tr align="left" height="26" \(dayIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
                    """
                    
                    if( judgeIndex == 0){
                        htmlString += """
                        <td rowspan="\(meet.judges.count)" valign="top">\(dateFormatter.string(from: day.meetDate))</td>
                        """
                    }
                    let rate = String(format: "$%0.2f/hr", judge.level.rate)
                    let hours = String(format: "%0.2f", fee.getHours())
                    let total = numberFormatter.string(from: fee.getFeeTotal() as NSNumber)!
                    htmlString += """
                        <td>\(judge.name)</td>
                        <td>\(rate)</td>
                        <td>\(judge.level.description)</td>
                        <td>\(hours)</td>
                        <td>\(total)</td>
                        </tr>
                    """
                }
            }
            
            let colorString = dayIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : ""
            let totalDayCost = numberFormatter.string(from: meet.totalJudgesFeeForDay(dayIndex: dayIndex) as NSNumber)!
            htmlString += """
                <tr align="left" height="26" \(colorString)>
                    <th colspan="4"></th>
                    <th align="left">Total Day Fees</th>
                    <th>\(totalDayCost)</th>
                </tr>
            """
        }
        
        return htmlString
    }
    
    static func generateFeeTableFooter(meet: Meet) -> String{
        return """
            <tr align="left" height="26" bgcolor="lightgray">
                <th colspan="4"></th>
                <th align="left">Total Meet Fees</th>
                <th>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</th>
            </tr>
        </table>
        """
    }
}
