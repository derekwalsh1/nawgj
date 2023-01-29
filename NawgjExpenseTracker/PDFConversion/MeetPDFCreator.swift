//
//  MeetPDFCreator.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/30/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import PDFKit
import UIKit

class MeetPDFCreator : PDFCreator{
    
    static func createPDFFrom(meet: Meet, atLocation: URL){
        
        dateFormatter.dateStyle = .full
        dateFormatterShort.dateStyle = .short
        dateFormatterMedium.dateStyle = .medium
        timeFormatter.timeStyle = .medium
        
        numberFormatter.numberStyle = .currency
        
        var html = generateHTMLHeader()
        html += generateMeetSummaryTable(meet: meet)
        html += generateInvoiceTable(meet: meet)
        html += generateCheckList(meet: meet)
        html += generateFeeTable(meet: meet)
        html += generateMeetDayDetailsTable(meet: meet)
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
        let page = CGRect(x: 20, y: 20, width: 680, height: 960) // A4, 72 dpi
        let printable = CGRect(x: 20, y: 20, width: 680, height: 960) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(printable, forKey: "printableRect")
        
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: 750, height: 1060), nil)
        
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
                    table, tr, td, th {
                    page-break-inside: avoid;
                    }
                    tr {
                    page-break-before: auto;
                    }
                }
        
                @page {
                size: landscape;
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
            datesString += "\(index == 0 ? "" : "<br>")\(dateFormatter.string(from: day.meetDate)) - \(String(format: "%0.2f hrs", day.totalTimeInHours())) (\(String(format: "%d", day.breaks)) break\(day.breaks == 1 ? "" : "s"))"
        }
        
        let sortedJudges = meet.judges.sorted(by: { $0.name < $1.name })
        var judgeNames = ""
        for (index, judge) in sortedJudges.enumerated(){
            judgeNames += "\(index == 0 ? "" : "<br>")\(judge.name) - \(judge.level.fullDescription)"
        }
        
        let totalFeesString = numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!
        let totalHoursString = String(format: "%0.2f Hours", meet.totalMeetHours())
        
        return """
        <h1 class="pagebreak-before">Meet Summary: \(meet.name)</h1>
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
                <th valign="top">Mileage Rate</th>
                <td>\(String(format: "$%0.2f/mile", meet.getMileageRate()))</td>
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
                <th valign="top">Total Billable Judge Hours</th>
                <td>\(String(format: "%0.2f Hours", meet.totalBillableJudgeHours()))</td>
            </tr>
            <tr align="left" height="26" bgcolor="#EEEEEE">
                <th valign="top">Total Due</th>
                <td><b>\(totalFeesString)</b></td>
            </tr>
        </table>
        """
    }
    
    
    static func generateCheckList(meet: Meet) -> String{
        
        var htmlString : String = """
        
        <h1 class="pagebreak-before">Checklist Report:</h1>
        <hr>
        <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
        <td>
        <b>Meet:</b>\(meet.name) | <b>Date:</b> \(dateFormatter.string(from: meet.startDate))
        </td>
        </tr>
        </table>
        <table border="1" cellpadding="0" cellspacing="0" width="100%">
        <tr align="left" height="26" "bgcolor=\"#BBBBBB\"">
        <th>Name</th>
        <th>Rate</th>
        <th>Miles</th>
        <th>W9</th>
        <th>Receipts</th>
        <th>Paid</th>
        <th width="30%">Notes</th>
        </tr>
        """
        
        let sortedJudges = meet.judges.sorted(by: { $0.name < $1.name })
        for (judgeIndex, judge) in sortedJudges.enumerated(){
            let mileageExpense = judge.expenses.first(where: {$0.type == Expense.ExpenseType.Mileage})
            let mileage = String(format: "%0.2f", mileageExpense?.amount ?? 0)
            htmlString += """
            <tr align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
            <style type="text/css">
            @media print {
            .pagebreak-before:first-child { display: block; page-break-before: avoid; }
            .pagebreak-before { display: block; page-break-before: always; }
            }
            </style>
            <td>\(judge.name)</td>
            <td>\(judge.level.fullDescription)</td>
            <td>\(mileage)</td>
            <td align="middle">\(judge.isW9Received() ? "Received" : "Not Received")</td>
            <td align="middle">\(judge.isReceiptsReceived() ? "Received" : "Not Received")</td>
            <td align="middle">\(judge.isPaid() ? "Paid" : "Not Paid")</td>
            <td>\(judge.getNotes())</td>
            </tr>
            """
        }
        htmlString += """
        </table>
        """
        /*
        htmlString += """
        <tr align="left" height="26" "bgcolor=\"#BBBBBB\"">
        <style type="text/css">
        @media print {
        .pagebreak-before:first-child { display: block; page-break-before: avoid; }
        .pagebreak-before { display: block; page-break-before: always; }
        }
        </style>
            <td>Totals:</td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
        </table>
        """*/
        return htmlString
    }
    
    static func generateInvoiceTable(meet: Meet) -> String{
        var htmlString : String = """

        <h1 class="pagebreak-before">Meet Invoice:</h1>
        <hr>
        <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
            <td>
                <b>Meet:</b>\(meet.name) | <b>Date:</b> \(dateFormatter.string(from: meet.startDate)) | <b>Description/Levels</b>: \(meet.meetDescription)
            </td>
        </tr>
        </table>
        <table border="1" cellpadding="1" cellspacing="0" width="100%">
        <tr align="left" height="26" "bgcolor=\"#BBBBBB\"">
            <th>Name</th>
            <th>Rate</th>
            <th colspan="3">Fees</th>
            <th colspan="2">Expenses</th>
            <th>Taxable Fee</th>
            <th>Total Due</th>
            <th>Paid</th>
        </tr>
        """
        
        for (judgeIndex, judge) in meet.judges.sorted(by: { $0.name < $1.name }).enumerated(){
            
            // Determine how many rows are needed for this judge; it will be the greater of the
            // number of days worked and the number of expense types with an additional row for
            // the judge totals
            judge.fees = judge.fees.sorted(by: {$0.date < $1.date})
            let filteredExpenses = judge.expenses.filter { $0.amount > 0.0 }
            let totalRows = max(filteredExpenses.count, judge.fees.count)

            if totalRows > 0 {
                for rowNumber in 0...totalRows - 1{
                    htmlString += """
                        <tr align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
                        <style type="text/css">
                        @media print {
                        .pagebreak-before:first-child { display: block; page-break-before: avoid; }
                        .pagebreak-before { display: block; page-break-before: always; }
                        }
                        </style>
                    """
                    
                    if rowNumber == 0{ // We are on the first row that prints
                        let date = dateFormatterShort.string(from: judge.fees[rowNumber].date)
                        let hours = judge.fees[rowNumber].getHours()
                        let dayFee = numberFormatter.string(from: judge.fees[rowNumber].getFeeTotal() as NSNumber)
                        
                        var expenseName = ""
                        var expenseTotal = ""
                        if let expense = filteredExpenses.count > 0  ? filteredExpenses[0] : nil {
                            expenseName = expense.type == Expense.ExpenseType.Mileage ? String(format: "%0.2f Miles", expense.amount) : expense.type.description
                            expenseTotal = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                        }
                        
                        let feesRowSpan = judge.fees.count - 1 == rowNumber ? totalRows - rowNumber : 0
                        let expensesRowSpan = filteredExpenses.count - 1 <= rowNumber ? totalRows - rowNumber : 0
                        
                        htmlString += """
                        <td rowspan="\(totalRows + (judge.isMeetRef() ? 1 : 0))" valign="top">\(judge.name)</td>
                            <td rowspan="\(totalRows + (judge.isMeetRef() ? 1 : 0))" valign="top">\(judge.level.fullDescription)</td>
                            <td rowspan="\(feesRowSpan)" valign="top">\(date)</td>
                            <td rowspan="\(feesRowSpan)" valign="top">\(hours) hrs</td>
                            <td rowspan="\(feesRowSpan)" valign="top" align="right">\(dayFee ?? "0.0")</td>
                        """
                        if filteredExpenses.count == 0 {
                            htmlString += """
                            <td colspan="2" rowspan="\(expensesRowSpan)" valign="top">\(expenseName)</td>
                            """
                        }
                        else {
                            htmlString += """
                            <td rowspan="\(expensesRowSpan)" valign="top">\(expenseName)</td>
                            <td rowspan="\(expensesRowSpan)" valign="top" align="right">\(expenseTotal)</td>
                            """
                            
                        }
                        htmlString += """
                            <td rowspan="\(totalRows + (judge.isMeetRef() ? 1 : 0))">&nbsp;</td>
                            <td rowspan="\(totalRows + (judge.isMeetRef() ? 1 : 0))">&nbsp;</td>
                            <td rowspan="\(totalRows + (judge.isMeetRef() ? 1 : 0))">&nbsp;</td>
                        </tr>
                        """
                    }/*
                    else if rowNumber == totalRows - 1 && judge.isMeetRef(){ // We are adding in the judge ref fee (which is taxable)
                        let totalRefFee = judge.getMeetRefereeFee()
                        htmlString += """
                            <td colspan="2" valign="top">Meet Referee Fee</td>
                            <td valign="top" align="right">\(totalRefFee)</td>
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                        """
                    }*/
                    else{ // We are in the middle rows
                        if rowNumber < judge.fees.count{
                            let feesRowSpan = judge.fees.count - 1 == rowNumber ? totalRows - rowNumber : 0
                            let date = dateFormatterShort.string(from: judge.fees[rowNumber].date)
                            let hours = judge.fees[rowNumber].getHours()
                            let dayFee = numberFormatter.string(from: judge.fees[rowNumber].getFeeTotal() as NSNumber)!
                            htmlString += """
                                <td rowspan="\(feesRowSpan)" valign="top">\(date)</td>
                                <td rowspan="\(feesRowSpan)" valign="top">\(hours) hrs</td>
                                <td rowspan="\(feesRowSpan)" valign="top" align="right">\(dayFee)</td>
                            """
                        }
                        
                        if rowNumber < filteredExpenses.count{
                            let expensesRowSpan = filteredExpenses.count - 1 == rowNumber ? totalRows - rowNumber : 0
                            
                            let expense = filteredExpenses[rowNumber]
                            let expenseName = expense.type == Expense.ExpenseType.Mileage ? String(format: "%0.2f Miles", expense.amount) : expense.type.description
                            let expenseTotal = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                            htmlString += """
                                <td rowspan="\(expensesRowSpan)" valign="top">\(expenseName)</td>
                                <td rowspan="\(expensesRowSpan)" valign="top" align="right">\(expenseTotal)</td>
                            """
                        }
                        
                        if rowNumber < filteredExpenses.count || rowNumber < judge.fees.count{
                            htmlString += """
                                </tr>
                            """
                        }
                    }
                }
            }
            
            
            // Add a row for judge ref fees if the judge is a meet referee
            if judge.isMeetRef(){
                htmlString += """
                <tr align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
                <style type="text/css">
                @media print {
                .pagebreak-before:first-child { display: block; page-break-before: avoid; }
                .pagebreak-before { display: block; page-break-before: always; }
                }
                </style>
                <td colspan="2" align="right">Meet Referee Fee</td>
                <td align="right">\(judge.getMeetRefereeFee())</td>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
                </tr>
                """
            }
            
            htmlString += """
            <tr align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
            <style type="text/css">
            @media print {
            .pagebreak-before:first-child { display: block; page-break-before: avoid; }
            .pagebreak-before { display: block; page-break-before: always; }
            }
            </style>
            """
            let totalFees = numberFormatter.string(from: judge.totalFees() as NSNumber)!
            let totalExpenses = numberFormatter.string(from: judge.totalExpenses() as NSNumber)!
            let totalHours = String(format: "%0.1f hrs", judge.totalBillableHours())
            let totalDue = numberFormatter.string(from: judge.totalCost() as NSNumber)!
            htmlString += """
            <td colspan="3" align="left"><b>Totals for \(judge.name):</b></td>
            <td><b>\(totalHours)</b></td>
            <td align="right"><b>\(totalFees)</b></td>
            <td>&nbsp;</td>
            <td align="right"><b>\(totalExpenses)</b></td>
            <td align="right"><b>\(totalFees)</b></td>
            <td align="right"><b>\(totalDue)</b></td>
            <td align="center"><b>\(judge.isPaid() ? "Paid" : "Not Paid")</b></td>
            </tr>
            """
        }
        
        htmlString += """
        <tr align="left" height="26" bgcolor="#BBBBBB" : "")>
        <style type="text/css">
        @media print {
        .pagebreak-before:first-child { display: block; page-break-before: avoid; }
        .pagebreak-before { display: block; page-break-before: always; }
        }
        </style>
            <td colspan="3" align="left"><b>Grand Total for all Judges:</b></td>
            <td><b>\(meet.totalBillableJudgeHours()) hrs</b></td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td>&nbsp;</td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFeesAndExpenses() - meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFeesAndExpenses() as NSNumber)!)</b></td>
            <td>&nbsp;</td>
        </tr>
        """
        
        htmlString += """
        </table>
        """
        
        return htmlString
    }
    
    static func generateFeeTable(meet: Meet) -> String{
        var htmlString : String = """

        <h1 class="pagebreak-before">Daily Judging Fees:</h1>
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
                    <style type="text/css">
                    @media print {
                    .pagebreak-before:first-child { display: block; page-break-before: avoid; }
                    .pagebreak-before { display: block; page-break-before: always; }
                    }
                    </style>
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
        
        htmlString += """
            <tr align="left" height="26" bgcolor="lightgray">
            <th colspan="4"></th>
            <th align="left">Total Meet Fees</th>
            <th>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</th>
            </tr>
        </table>
        """
        
        return htmlString
    }
    
    static func generateMeetDayDetailsTable(meet: Meet) -> String{
        
        let numberOfDays = meet.days.count
        
        if numberOfDays > 0 {
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
            </table>
            """
            
            return htmlString
        }
        
        return ""
    }
}
