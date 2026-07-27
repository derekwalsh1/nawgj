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
        // Prepare formatters/date/number styles used in HTML
        dateFormatter.dateStyle = .full
        dateFormatterShort.dateStyle = .short
        dateFormatterMedium.dateStyle = .medium
        timeFormatter.timeStyle = .medium
        numberFormatter.numberStyle = .currency

        // Page size: US Letter portrait
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let page = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // Standard margins - NO header/footer during individual section renders
        let margin: CGFloat = 36
        
        let printable = CGRect(x: margin,
                               y: margin,
                               width: pageWidth - (margin * 2),
                               height: pageHeight - (margin * 2))
        
        // Helper function to render a single section to PDF data WITHOUT headers/footers
        func renderSectionToPDF(_ htmlContent: String) -> Data {
            let html = generateHTMLSection(content: htmlContent)
            let fmt = UIMarkupTextPrintFormatter(markupText: html)
            let renderer = UIPrintPageRenderer()
            renderer.headerHeight = 0  // No header
            renderer.footerHeight = 0  // No footer
            renderer.setValue(page, forKey: "paperRect")
            renderer.setValue(printable, forKey: "printableRect")
            renderer.addPrintFormatter(fmt, startingAtPageAt: 0)
            renderer.prepare(forDrawingPages: NSMakeRange(0, 0))
            
            let pageCount = renderer.numberOfPages
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, page, nil)
            for i in 0..<pageCount {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }
            UIGraphicsEndPDFContext()
            
            return pdfData as Data
        }
        
        // Render each section as a separate PDF
        let sectionPDFs = [
            renderSectionToPDF(generateMeetSummaryTable(meet: meet)),
            renderSectionToPDF(generateInvoiceTable(meet: meet)),
            renderSectionToPDF(generateCheckList(meet: meet)),
            renderSectionToPDF(generateFeeTable(meet: meet)),
            renderSectionToPDF(generateMeetDayDetailsTable(meet: meet))
        ]
        
        // Merge all section PDFs into one final PDF
        let finalPDF = PDFDocument()
        var pageIndex = 0
        
        for sectionData in sectionPDFs {
            if let sectionPDF = PDFDocument(data: sectionData) {
                for i in 0..<sectionPDF.pageCount {
                    if let page = sectionPDF.page(at: i) {
                        finalPDF.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            }
        }
        
        // Write the merged PDF to the output location
        if let finalData = finalPDF.dataRepresentation() {
            try? finalData.write(to: atLocation)
        }
    }
    
    /// Wrap a section of HTML content in a complete HTML document
    static func generateHTMLSection(content: String) -> String {
        return """
<html>
<head>
<meta charset="UTF-8">
<style type="text/css">
@media print {
    thead { display: table-header-group; }
    tfoot { display: table-footer-group; }
    tbody { display: table-row-group; }
}
@page { size: 8.5in 11in; margin: 0; }
body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 8pt; margin: 0; padding: 0; }
h1 { font-size: 12pt; margin: 6px 0 4px 0; }
table { width: 100%; font-size: 7.5pt; table-layout: fixed; border-collapse: collapse; }
td, th { padding: 1px 3px; word-wrap: break-word; overflow-wrap: break-word; }
th { font-weight: bold; }
tr.light { background-color: #EEEEEE }
tbody.details-table { page-break-inside: auto; }
table.lightgray-border, table.lightgray-border th, table.lightgray-border td {
    border: 1px solid lightgray;
    border-collapse: collapse;
}
</style>
</head>
<body>
\(content)
</body>
</html>
"""
    }

    /// Compose the full meet HTML (header + various sections + footer). If `scale` != 1.0, inject compacting CSS.
    static func generateMeetHTML(meet: Meet, scale: CGFloat = 1.0) -> String {
        let scaleCSS = scale != 1.0 ? "body { transform: scale(\(scale)); transform-origin: top left; width: \(100.0/scale)% }" : ""
        // Build header with scale CSS injected
        let header = """
<html>
<head>
<meta charset="UTF-8">
<style type="text/css">
@media print {
    thead { display: table-header-group; }
    tfoot { display: table-footer-group; }
    tbody { display: table-row-group; }
    /* Use h1 elements for page breaks - more reliable in UIMarkupTextPrintFormatter */
    h1 { page-break-before: always; }
    h1:first-of-type { page-break-before: avoid; }
}
@page { size: 8.5in 11in; margin: 0; }
body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 8pt; margin: 0; padding: 0; }
h1 { font-size: 12pt; margin: 6px 0 4px 0; }
table { width: 100%; font-size: 7.5pt; table-layout: fixed; border-collapse: collapse; }
td, th { padding: 1px 3px; word-wrap: break-word; overflow-wrap: break-word; }
th { font-weight: bold; }
tr.light { background-color: #EEEEEE }
tbody.details-table { page-break-inside: auto; }
\(scaleCSS)
</style>
</head>
<body>
"""

         var html = header
         html += generateMeetSummaryTable(meet: meet)
         html += generateInvoiceTable(meet: meet)
         html += generateCheckList(meet: meet)
         html += generateFeeTable(meet: meet)
         html += generateMeetDayDetailsTable(meet: meet)
         html += generateHTMLFooter()
 
         return html
     }
    
    static func generateHTMLHeader() -> String{
        return """
        <html>
            <head>
                <meta charset="UTF-8">
                <style type="text/css">
        
                @media print {
                    thead { display: table-header-group; }
                    tfoot { display: table-footer-group; }
                    tbody { display: table-row-group; }
                    /* Force page breaks before all major section headings except the very first one */
                    h1.pagebreak-before:first-of-type { page-break-before: avoid; }
                    h1.pagebreak-before { page-break-before: always; }
                    /* Allow row breaks for pagination */
                    tr { page-break-inside: auto; page-break-after: auto; }
                    tbody.details-table { page-break-inside: auto; }
                }
        
                @page {
                    size: 8.5in 11in;
                    margin: 0;
                }
                
                body {
                    font-family: -apple-system, Helvetica, Arial, sans-serif;
                    font-size: 8pt;
                    margin: 0;
                    padding: 0;
                }
                
                h1 {
                    font-size: 12pt;
                    margin: 6px 0;
                }
                
                table {
                    width: 100%;
                    font-size: 7.5pt;
                    table-layout: fixed;
                    border-collapse: collapse;
                }
                
                td, th {
                    padding: 1px 3px;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                }
                
                th {
                    font-weight: bold;
                }
        
                table.lightgray-border, 
                table.lightgray-border th, 
                table.lightgray-border td {
                    border: 1px solid lightgray;
                    border-collapse: collapse;
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
        <h1>Meet Summary: \(meet.name)</h1>
        <hr>
        <table cellpadding="5" cellspacing="0" border="0" style="width:100%;">
            <tr align="left">
                <th style="width:35%;">Meet Name</th>
                <td style="width:65%;">\(meet.name)</td>
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
        
        <h1>Checklist Report:</h1>
        <hr>
        <table border="0" cellpadding="0" cellspacing="0" width="100%">
        <tr>
        <td>
        <b>Meet:</b>\(meet.name) | <b>Date:</b> \(dateFormatter.string(from: meet.startDate))
        </td>
        </tr>
        </table>
        <table border="1" cellpadding="0" cellspacing="0" width="100%">
        <thead>
        <tr align="left" height="26" bgcolor="#BBBBBB">
        <th>Name</th>
        <th>Rate</th>
        <th>Miles</th>
        <th>W9</th>
        <th>Receipts</th>
        <th>Paid</th>
        <th width="30%">Notes</th>
        </tr>
        </thead>
        <tbody class="details-table">
        """
        
        let sortedJudges = meet.judges.sorted(by: { $0.name < $1.name })
        for (judgeIndex, judge) in sortedJudges.enumerated(){
            let mileageExpense = judge.expenses.first(where: {$0.type == Expense.ExpenseType.Mileage})
            let mileage = String(format: "%0.2f", mileageExpense?.amount ?? 0)
            htmlString += """
            <tr align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
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
        </tbody>
        </table>
        """
         
         return htmlString
     }
    
    static func generateInvoiceTable(meet: Meet) -> String{
        var htmlString = ""
        htmlString += "<h1>Meet Invoice:</h1>\n"
        htmlString += "<hr>\n"
        htmlString += "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n"
        htmlString += "<tr>\n<td style=\"font-size: 7pt;\">\n"
        htmlString += "<b>Meet:</b>\(meet.name) | <b>Date:</b> \(dateFormatter.string(from: meet.startDate)) | <b>Description/Levels</b>: \(meet.meetDescription)\n"
        htmlString += "</td>\n</tr>\n</table>\n\n"
        htmlString += "<table class=\"lightgray-border\" border=\"1\" cellpadding=\"1\" cellspacing=\"0\" width=\"100%\" style=\"table-layout: fixed; font-size: 6pt;\">\n"
        htmlString += "<thead>\n<tr class=\"lightgray-border\" align=\"left\" height=\"18\" bgcolor=\"#BBBBBB\">\n"
        htmlString += "<th width=\"12%\">Name</th>\n<th width=\"11%\">Rate</th>\n<th width=\"7%\">Date</th>\n<th width=\"7%\">Hours</th>\n"
        htmlString += "<th width=\"9%\">Fees</th>\n<th width=\"11%\">Expense</th>\n<th width=\"9%\">Amount</th>\n"
        htmlString += "<th width=\"9%\">Taxable Fee</th>\n<th width=\"10%\">Total Due</th>\n<th width=\"6%\">Paid</th>\n"
        htmlString += "</tr>\n</thead>\n<tbody class=\"details-table\" style=\"font-size: 6pt;\">\n"
        
        for (judgeIndex, judge) in meet.judges.sorted(by: { $0.name < $1.name }).enumerated(){
            
            // Determine how many rows are needed for this judge; it will be the greater of the
            // number of days worked and the number of expense types with an additional row for
            // the judge totals. If the judge is a meet ref, add an additional expense item.
            judge.fees = judge.fees.sorted(by: {$0.date < $1.date})
            let filteredExpenses = judge.expenses.filter { $0.getExpenseTotal() != 0.0}
            let totalRows = max(filteredExpenses.count, judge.fees.count + (judge.isMeetRef() ? 1 : 0))
           
            // Handle the case where there are no expenses and no fees (no days added and no expenses reported)
            if totalRows > 0 {
                for rowNumber in 0...totalRows - 1{
                    htmlString += """
                        <tr class="lightgray-border" align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
                    """
                    
                    // We are on the first row that prints. Each row has 10 columns.
                    if rowNumber == 0 {
                       
                        htmlString += """
                            <td rowspan="\(totalRows)" valign="top">\(judge.name)</td>
                            <td rowspan="\(totalRows)" valign="top">\(judge.level.fullDescription)</td>
                        """
                        
                        if judge.fees.count > 0 {
                            let date = dateFormatterShort.string(from: judge.fees[rowNumber].date)
                            let hours = judge.fees[rowNumber].getHours()
                            let dayFee = numberFormatter.string(from: judge.fees[rowNumber].getFeeTotal() as NSNumber)
                            
                            htmlString += """
                                <td valign="top">\(date)</td>
                                <td valign="top">\(hours) hrs</td>
                                <td valign="top" align="right">\(dayFee ?? "0.0")</td>
                            """
                        }
                        else {
                            htmlString += """
                                <td colspan="2">&nbsp;</td>
                                <td>&nbsp;</td>
                            """
                        }
                        
                        // Add a blank entry if there are no expenses. 2 more columns
                        if filteredExpenses.count == 0 {
                            htmlString += """
                            <td>&nbsp;</td>
                            <td>&nbsp;</td>
                            """
                        }
                        else {
                            var expenseName = ""
                            var expenseTotal = ""
                            
                            // If there's an expense, update the expense name and total variables
                            if let expense = filteredExpenses.count > 0  ? filteredExpenses[rowNumber] : nil {
                                expenseName = expense.type == Expense.ExpenseType.Mileage ? String(format: "%0.2f Miles", expense.amount) : expense.type.description
                                expenseTotal = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                            }
                            htmlString += """
                            <td valign="top">\(expenseName)</td>
                            <td valign="top" align="right">\(expenseTotal)</td>
                            """
                        }
                        
                        // Add entries for the taxable fees, total due, and paid columns.
                        htmlString += """
                            <td rowspan="\(totalRows)">&nbsp;</td>
                            <td rowspan="\(totalRows)">&nbsp;</td>
                            <td rowspan="\(totalRows)">&nbsp;</td>
                        </tr>
                        """
                    }
                    
                    // Now we are adding the middle rows
                    else{
                        // Add the fee items
                        if rowNumber < judge.fees.count{
                            let date = dateFormatterShort.string(from: judge.fees[rowNumber].date)
                            let hours = judge.fees[rowNumber].getHours()
                            let dayFee = numberFormatter.string(from: judge.fees[rowNumber].getFeeTotal() as NSNumber)!
                            htmlString += """
                                <td valign="top">\(date)</td>
                                <td valign="top">\(hours) hrs</td>
                                <td valign="top" align="right">\(dayFee)</td>
                            """
                        }
                        else{
                            // If the judge is a meet referee, add this as the last fee if we've added all the rest of the fees.
                            if judge.isMeetRef() && rowNumber < judge.fees.count + 1{
                                let meetRefFee = numberFormatter.string(from: judge.getMeetRefereeFee() as NSNumber)!
                                htmlString += """
                                    <td colspan="2">Meet Referee Fee</td>
                                    <td align="right">\(meetRefFee)</td>
                                """
                            }
                            else{
                                htmlString += """
                                    <td colspan="2">&nbsp;</td>
                                    <td>&nbsp;</td>
                                """
                            }
                        }
                        
                        if rowNumber < filteredExpenses.count{
                            //let expensesRowSpan = filteredExpenses.count - 1 == rowNumber ? totalRows - rowNumber : 0
                            
                            let expense = filteredExpenses[rowNumber]
                            let expenseName = expense.type == Expense.ExpenseType.Mileage ? String(format: "%0.2f Miles", expense.amount) : expense.type.description
                            let expenseTotal = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                            htmlString += """
                                <td valign="top">\(expenseName)</td>
                                <td valign="top" align="right">\(expenseTotal)</td>
                            """
                        }
                        else{
                            htmlString += """
                                <td>&nbsp;</td>
                                <td>&nbsp;</td>
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
            
            htmlString += """
            <tr class="lightgray-border" align="left" height="26" \(judgeIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
            """
            
            let totalFees = numberFormatter.string(from: judge.totalFees() as NSNumber)!
            let totalExpenses = numberFormatter.string(from: judge.totalExpenses() as NSNumber)!
            let totalHours = String(format: "%0.1f hrs", judge.totalBillableHours())
            let totalDue = numberFormatter.string(from: judge.totalCost() as NSNumber)!
            htmlString += """
            <td colspan="3" align="left"><b>Totals for \(judge.name)</b></td>
            <td><b>\(totalHours)</b></td>
            <td align="right"><b>\(totalFees)</b></td>
            <td>&nbsp;</td>
            <td align="right"><b>\(totalExpenses)</b></td>
            <td align="right"><b>\(totalFees)</b></td>
            <td align="right"><b><u>\(totalDue)</u></b></td>
            <td align="center"><b>\(judge.isPaid() ? "Yes" : "No")</b></td>
            </tr>
            """
        }
        
        
        htmlString += """
        <tr class="lightgray-border" align="left" height="26" bgcolor="#BBBBBB">
            <td colspan="3" align="left"><b>Grand Total for all Judges:</b></td>
            <td><b>\(meet.totalBillableJudgeHours()) hrs</b></td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td>&nbsp;</td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFeesAndExpenses() - meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</b></td>
            <td id="one" align="right"><b>\(numberFormatter.string(from: meet.totalJudgeFeesAndExpenses() as NSNumber)!)</b></td>
            <td>&nbsp;</td>
        </tr>
        """
        
        htmlString += """
        </tbody>
        </table>
        """
        
        return htmlString
    }
    
    /// The Session (within `day`) that `fee` belongs to, if any - used to
    /// label rows on days with more than one session.
    private static func sessionName(for fee: Fee, in day: MeetDay) -> String {
        day.sessions.first(where: { $0.getUUID() == fee.getSessionUUID() })?.name ?? ""
    }

    static func generateFeeTable(meet: Meet) -> String{
        var htmlString = ""
        htmlString += "<h1>Daily Judging Fees:</h1>\n"
        htmlString += "<hr>\n"
        htmlString += "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n"
        htmlString += "<thead>\n<tr align=\"left\" height=\"26\">\n"
        htmlString += "<th>Date</th>\n<th>Judge Name</th>\n<th>Rate</th>\n<th>Rate Code</th>\n<th>Hours</th>\n<th>Fee</th>\n"
        htmlString += "</tr>\n</thead>\n<tbody class=\"details-table\">\n"
        
        for (dayIndex, day) in meet.days.sorted(by: { $0.meetDate < $1.meetDate }).enumerated(){
            // One row per (judge, fee) for the day - a judge can now have
            // more than one fee on the same day (one per session).
            var rows: [(judge: Judge, fee: Fee)] = []
            for judge in meet.judges.sorted(by: { $0.name < $1.name }) {
                let judgeFeesForDay = judge.fees
                    .filter { $0.date == day.meetDate }
                    .sorted { sessionName(for: $0, in: day) < sessionName(for: $1, in: day) }
                for fee in judgeFeesForDay {
                    rows.append((judge, fee))
                }
            }

            for (rowIndex, row) in rows.enumerated() {
                htmlString += """
                <tr align="left" height="26" \(dayIndex % 2 == 0 ? "bgcolor=\"#EEEEEE\"" : "")>
                """

                if rowIndex == 0 {
                    htmlString += """
                    <td rowspan="\(rows.count)" valign="top">\(dateFormatter.string(from: day.meetDate))</td>
                    """
                }
                let judgeName = day.sessions.count > 1
                    ? "\(row.judge.name) (\(sessionName(for: row.fee, in: day)))"
                    : row.judge.name
                let rate = String(format: "$%0.2f/hr", row.judge.level.rate)
                let hours = String(format: "%0.2f", row.fee.getHours())
                let total = numberFormatter.string(from: row.fee.getFeeTotal() as NSNumber)!
                htmlString += """
                <td>\(judgeName)</td>
                <td>\(rate)</td>
                <td>\(row.judge.level.description)</td>
                <td>\(hours)</td>
                <td>\(total)</td>
                </tr>
                """
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
            <tr align="left" height="26" bgcolor="#BBBBBB">
            <th colspan="4"></th>
            <th align="left">Total Meet Fees</th>
            <th>\(numberFormatter.string(from: meet.totalJudgeFees() as NSNumber)!)</th>
            </tr>
        </tbody>
        </table>
        """
        
        return htmlString
    }
    
    static func generateMeetDayDetailsTable(meet: Meet) -> String {
        let numberOfDays = meet.days.count
        if numberOfDays == 0 { return "" }

        var html = ""
        html += "<h1>Meet Day Details</h1>\n"
        html += "<hr>\n"
        html += "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\">\n"

        // Header row: dates
        html += "<tr>\n<th align=\"left\">&nbsp;</th>\n"
        for i in 0..<numberOfDays {
            html += "<th align=\"left\">\(dateFormatterShort.string(from: meet.days[i].meetDate))</th>\n"
        }
        html += "</tr>\n"

        // Start Time
        html += "<tr>\n<th align=\"left\">Start Time</th>\n"
        for i in 0..<numberOfDays { html += "<td>\(timeFormatter.string(from: meet.days[i].startTime))</td>\n" }
        html += "</tr>\n"

        // End Time
        html += "<tr>\n<th align=\"left\">End Time</th>\n"
        for i in 0..<numberOfDays { html += "<td>\(timeFormatter.string(from: meet.days[i].endTime))</td>\n" }
        html += "</tr>\n"

        // Total Time
        html += "<tr>\n<th align=\"left\">Total Time</th>\n"
        for i in 0..<numberOfDays {
            let v = String(format: "%0.2f hrs", meet.days[i].totalTimeInHours())
            html += "<td>\(v)</td>\n"
        }
        html += "</tr>\n"

        // Breaks and Break Time
        html += "<tr>\n<th align=\"left\">Breaks</th>\n"
        for i in 0..<numberOfDays { html += "<td>\(meet.days[i].breaks)</td>\n" }
        html += "</tr>\n"

        html += "<tr>\n<th align=\"left\">Break Time</th>\n"
        for i in 0..<numberOfDays {
            let v = String(format: "%0.2f hrs", meet.days[i].breakTimeInHours())
            html += "<td>\(v)</td>\n"
        }
        html += "</tr>\n"

        // Billed Time
        html += "<tr>\n<th align=\"left\">Billed Time</th>\n"
        for i in 0..<numberOfDays {
            let v = String(format: "%0.2f hrs", meet.days[i].totalBillableTimeInHours())
            html += "<td>\(v)</td>\n"
        }
        html += "</tr>\n"

        // Judges working that day
        html += "<tr>\n<th align=\"left\">Judges</th>\n"
        for i in 0..<numberOfDays {
            let judges = meet.judges.filter({ $0.getFeesFor(date: meet.days[i].meetDate) > 0 })
            var names = ""
            for (j, judge) in judges.enumerated() {
                names += (j == 0 ? "" : "<br>") + judge.name
            }
            html += "<td valign=\"top\">\(names)</td>\n"
        }
        html += "</tr>\n"

        html += "</table>\n"

        return html
    }

}
