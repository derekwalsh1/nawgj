//
//  MeetPDFCreator.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 2/19/19.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import PDFKit
import UIKit

class JudgePDFCreator : PDFCreator{
    
    static func createPDFFrom(judge: Judge, meet: Meet, atLocation: URL){
        
        dateFormatter.dateStyle = .full
        dateFormatterShort.dateStyle = .short
        dateFormatterMedium.dateStyle = .medium
        timeFormatter.timeStyle = .medium
        
        numberFormatter.numberStyle = .currency
        
        var html = generateHTMLHeader()
        html += generateJudgeFeesTable(judge: judge, meet: meet)
        html += generateJudgeExpensesTable(judge: judge, meet : meet)
        html += generateHTMLFooter()
        
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = MeetUIPrintPageRender(date: Date(), meetName: meet.name)
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        render.footerHeight = 10
        render.headerHeight = 10
                
        // 3. Assign paperRect and printableRect
        //let page = CGRect(x: 20, y: 20, width: 595.2, height: 841.2) // A4, 72 dpi
        //let printable = CGRect(x: 20, y: 20, width: 595.2, height: 841.2) // A4, 72 dpi
        let page = CGRect(x: 20, y: 20, width: 892, height: 1261) // A4, 72 dpi
        let printable = CGRect(x: 20, y: 20, width: 892, height: 1261) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(printable, forKey: "printableRect")
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 942, height: 1311), nil)
        
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
    
    static func generateJudgeFeesTable(judge: Judge, meet: Meet) -> String{
        let sortedDays = meet.days.sorted(by: { $0.meetDate < $1.meetDate })
        var datesString = ""
        for (index, day) in sortedDays.enumerated(){
            datesString += "\(index == 0 ? "" : "<br>")\(dateFormatter.string(from: day.meetDate)) - \(String(format: "%0.2f hrs", day.totalTimeInHours())) (\(String(format: "%d", day.breaks)) break\(day.breaks != 0 ? "s" : ""))"
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
        <th valign="top">Mileage Rate</th>
        <td>\(String(format: "$%0.2f/mile", meet.getMileageRate()))</td>
        </tr>
        </table>
        
        
        
        """
    }
    
    static func generateJudgeExpensesTable(judge: Judge, meet: Meet) -> String{
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
    
    static func generateMeetDayDetailsTable(meet: Meet) -> String{
        
        let numberOfDays = meet.days.count
        
        var htmlString : String = """

        <h1 class="pagebreak-before">Meet Day Details</h1>
        <hr>
        <table border="0" cellpadding="0" cellspacing="0" width="100%">
            <tr bgcolor=\"EEEEEE">
                <th align="left">Date</th>
        """
        // The header row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <th align="left">\(dateFormatterShort.string(from: meet.days[index].meetDate))</th>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">Start Time</th>
        """
        // The start time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(timeFormatter.string(from: meet.days[index].startTime))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">End Time</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(timeFormatter.string(from: meet.days[index].endTime))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">Total Time</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(String(format: "%0.2f hrs", meet.days[index].totalTimeInHours()))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">Breaks</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(String(format: "%d", meet.days[index].breaks))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">Break Time</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(String(format: "%0.2f hrs", meet.days[index].breakTimeInHours()))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left">Billed Time</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td>\(String(format: "%0.2f hrs", meet.days[index].totalBillableTimeInHours()))</td>
            """
        }
        htmlString += """
        </tr>
        <tr>
        <th align="left" valign="top">Judges</th>
        """
        // The end time row
        for index in 0...numberOfDays - 1{
            htmlString += """
            <td valign="top">
            """
            let judges = meet.judges.filter({$0.getFeesFor(date: meet.days[index].meetDate) > 0})
            for (index, judge) in judges.enumerated(){
                htmlString += "\(index == 0 ? "" : "<br>")\(judge.name)"
            }
            htmlString += """
            </td>
            """
        }
        
        htmlString += """
        </tr>
        """
        
        
        // The start time row
        /*
         <td>Date</td>
         <td>Start Time</td>
         <td>End Time</td>
         <td>Total Time</td>
         <td>No. of Breaks</td>
         <td>Total Break Time</td>
         <td>No. of Judges</td>
         <td>Billed Hours</td>
         <td valign="top">Judges</td>
         <td>Total Judge Fees</td>
         </tr>
         */
        
        
        htmlString += """
        </table>
        """
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
