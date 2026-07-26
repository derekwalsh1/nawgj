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
        // Prepare formatters and number/date styles used inside HTML generation
        dateFormatter.dateStyle = .full
        dateFormatterShort.dateStyle = .short
        dateFormatterMedium.dateStyle = .medium
        timeFormatter.timeStyle = .medium
        numberFormatter.numberStyle = .currency

        // Page size: US Letter portrait (points)
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let page = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        // Candidate parameters to try to fit into one page
        let scales: [CGFloat] = [1.00, 0.96, 0.92, 0.88, 0.84, 0.80]
        let marginCandidates: [CGFloat] = [36, 18, 12] // 0.5", 0.25", ~0.166"
        let headerFooterCandidates: [(header: CGFloat, footer: CGFloat)] = [(8,24), (6,20), (4,16)]

        // Chosen defaults (will be updated by the search)
        var chosenHtml: String = generateJudgeInvoice(judge: judge, meet: meet, scale: 1.0)
         var chosenMargin: CGFloat = marginCandidates[0]
         var chosenHeader: CGFloat = headerFooterCandidates[0].header
         var chosenFooter: CGFloat = headerFooterCandidates[0].footer
         var chosenPageCount: Int = 0

        // Try combinations (scale -> margin -> header/footer). Stop at the first that yields 1 page.
        searchLoop: for s in scales {
            let htmlCandidate = generateJudgeInvoice(judge: judge, meet: meet, scale: s)
            let fmtCandidate = UIMarkupTextPrintFormatter(markupText: htmlCandidate)

            for margin in marginCandidates {
                for hf in headerFooterCandidates {
                    let testRenderer = JudgeUIPrintPageRender(date: Date(), judge: judge, name: meet.name)
                    testRenderer.headerHeight = hf.header
                    testRenderer.footerHeight = hf.footer

                    // Compute printable rect that leaves space for header/footer inside margins
                    let printable = CGRect(x: margin,
                                           y: margin + hf.header,
                                           width: pageWidth - (margin * 2),
                                           height: pageHeight - (margin * 2) - hf.header - hf.footer)

                    testRenderer.setValue(page, forKey: "paperRect")
                    testRenderer.setValue(printable, forKey: "printableRect")

                    testRenderer.printFormatters = []
                    testRenderer.addPrintFormatter(fmtCandidate, startingAtPageAt: 0)
                    testRenderer.prepare(forDrawingPages: NSMakeRange(0, 0))

                    let pc = testRenderer.numberOfPages
                    // If this candidate fits on one page, choose it and stop searching
                    if pc == 1 {
                        chosenHtml = htmlCandidate
                        chosenMargin = margin
                        chosenHeader = hf.header
                        chosenFooter = hf.footer
                        chosenPageCount = pc
                        break searchLoop
                    }

                    // Keep last tried candidate as a fallback
                    chosenHtml = htmlCandidate
                    chosenMargin = margin
                    chosenHeader = hf.header
                    chosenFooter = hf.footer
                    chosenPageCount = pc
                }
            }
        }

        // If none of the tried configs produced a single page, try one final aggressive fallback (scale 0.8, smallest margins)
        if chosenPageCount != 1 {
            let fallbackScale: CGFloat = 0.80
            let fallbackHtml = generateJudgeInvoice(judge: judge, meet: meet, scale: fallbackScale)
            let fallbackFmt = UIMarkupTextPrintFormatter(markupText: fallbackHtml)

            let fallbackMargin: CGFloat = 12
            let fallbackHeader: CGFloat = 4
            let fallbackFooter: CGFloat = 12

            let testRenderer = JudgeUIPrintPageRender(date: Date(), judge: judge, name: meet.name)
            testRenderer.headerHeight = fallbackHeader
            testRenderer.footerHeight = fallbackFooter
            let printable = CGRect(x: fallbackMargin,
                                   y: fallbackMargin + fallbackHeader,
                                   width: pageWidth - (fallbackMargin * 2),
                                   height: pageHeight - (fallbackMargin * 2) - fallbackHeader - fallbackFooter)
            testRenderer.setValue(page, forKey: "paperRect")
            testRenderer.setValue(printable, forKey: "printableRect")
            testRenderer.printFormatters = []
            testRenderer.addPrintFormatter(fallbackFmt, startingAtPageAt: 0)
            testRenderer.prepare(forDrawingPages: NSMakeRange(0, 0))

            let pc = testRenderer.numberOfPages
            if pc == 1 {
                chosenHtml = fallbackHtml
                chosenMargin = fallbackMargin
                chosenHeader = fallbackHeader
                chosenFooter = fallbackFooter
                chosenPageCount = pc
            }
        }

        // Final rendering using chosen configuration
        let finalFmt = UIMarkupTextPrintFormatter(markupText: chosenHtml)
        let render = JudgeUIPrintPageRender(date: Date(), judge: judge, name: meet.name)
        render.headerHeight = chosenHeader
        render.footerHeight = chosenFooter

        let finalPrintable = CGRect(x: chosenMargin,
                                    y: chosenMargin + chosenHeader,
                                    width: pageWidth - (chosenMargin * 2),
                                    height: pageHeight - (chosenMargin * 2) - chosenHeader - chosenFooter)
        render.setValue(page, forKey: "paperRect")
        render.setValue(finalPrintable, forKey: "printableRect")

        render.printFormatters = []
        render.addPrintFormatter(finalFmt, startingAtPageAt: 0)
        render.prepare(forDrawingPages: NSMakeRange(0, 0))

        let pageCount = render.numberOfPages

        // Create PDF and draw pages
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, page, nil)
        for i in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        // Write PDF to file
        pdfData.write(to: atLocation, atomically: true)
    }
    
    /// Generate judge invoice HTML. Optional `scale` applies a CSS transform to reduce overall size.
    static func generateJudgeInvoice(judge: Judge, meet: Meet, scale: CGFloat = 1.0) -> String{
         let paidCheckedString = judge.isPaid() ? "checked" : ""
         let w9CheckedString = judge.isW9Received() ? "checked" : ""
         let receiptsCheckedString = judge.isReceiptsReceived() ? "checked" : ""
         let feeList = judge.fees.sorted(by: { $0.date < $1.date })

        var datesString = ""
        if feeList.count > 0 {
            for (index, fee) in feeList.enumerated() {
                datesString.append(dateFormatter.string(from: fee.date))
                if index < feeList.count - 1 { datesString.append("<br>") }
            }
        }

        // If scale != 1.0 we inject a CSS rule to shrink the whole body
        let scaleCSS = scale != 1.0 ? "body { transform: scale(\(scale)); transform-origin: top left; width: \(100.0/scale)%; }" : ""

        var html = """
 <html>
 <head>
   <meta charset="UTF-8">
   <style type="text/css">
     @media print {
       .pagebreak-before:first-child { display: block; page-break-before: avoid; }
       .pagebreak-before { display: block; page-break-before: always; }
     }

     body {
       font-family: -apple-system, Helvetica, Arial, sans-serif;
       font-size: 7pt;
       margin: 0;
       padding: 0.15in; /* reduced page padding to save vertical space */
     }
     
     /* Scaling helper (applied when requested) */
     \(scaleCSS)

     .container {
       display: block;
       position: relative;
       padding-left: 16px;
       margin-bottom: 4px;
       cursor: default;
       font-size: 8px;
       -webkit-user-select: none;
       -moz-user-select: none;
       -ms-user-select: none;
       user-select: none;
     }

     /* Custom small checkbox */
     .container input { position: absolute; opacity: 0; height: 0; width: 0; }
     .checkmark { position: absolute; top: 0; left: 0; height: 12px; width: 12px; background-color: #fff; border: 1px solid #4d565e; box-sizing: border-box; }
     .container input:checked ~ .checkmark { background-color: #fff; }
     .container .checkmark:after { content: ""; position: absolute; display: none; left: 3px; top: 2px; width: 3px; height: 5px; border: solid #4d565e; border-width: 0 2px 2px 0; transform: rotate(45deg); }
     .container input:checked ~ .checkmark:after { display: block; }

     .large { font-size: 9px; }

     /* Make tables use fixed layout so column widths are predictable and compressible */
     table { table-layout: fixed; width: 100%; border-collapse: collapse; }
     th, td { padding: 1px 3px; vertical-align: top; word-wrap: break-word; }
     th { font-weight: 600; }
     hr { border: none; border-top: 1px solid #ccc; margin: 3px 0; }

     /* Small fonts for dense tables */
     .summary-table td, .summary-table th, .fees-table td, .fees-table th, .expenses-table td, .expenses-table th { font-size: 6.5pt; }
     h2 { margin-top:4px; font-size:9pt; }
   </style>
 </head>
 <body>
  <table class="summary-table" border="1" cellpadding="3" cellspacing="0">
    <tr>
      <td style="width:30%" align="center" valign="top">
        <div style="font-weight:bold; font-size:10px;">
          \(judge.name)
        </div>
        <div class="large">\(judge.level.description)</div>
      </td>
      <td style="width:35%" valign="top">
        <div style="display:block;">
          <label class="container">Paid<input type="checkbox" \(paidCheckedString) disabled><span class="checkmark"></span></label>
          <label class="container">W9 Received<input type="checkbox" \(w9CheckedString) disabled><span class="checkmark"></span></label>
          <label class="container">Receipts Received<input type="checkbox" \(receiptsCheckedString) disabled><span class="checkmark"></span></label>
        </div>
      </td>
      <td style="width:35%" valign="top">
        <div style="font-size:8px;"><strong>Notes:</strong><br>\(judge.getNotes())</div>
      </td>
    </tr>
    <tr>
      <td colspan="3">
        <table class="summary-table" cellpadding="2" cellspacing="0">
          <tr><th style="width:25%">Meet Name:</th><td style="width:75%">\(meet.name)</td></tr>
          <tr><th>Meet Dates:</th><td>\(datesString)</td></tr>
          <tr><th>Meet Location:</th><td>\(meet.location)</td></tr>
          <tr><th>Meet Description:</th><td>\(meet.meetDescription)</td></tr>
          <tr><th>Mileage Rate:</th><td>\(meet.getMileageRate())</td></tr>
        </table>
      </td>
    </tr>
  </table>

  <h2 style="margin-top:8px; font-size:10pt;">Meet Fee Summary</h2>
  <table class="fees-table" border="1" cellpadding="2" cellspacing="0">
    <tr><th style="width:25%">Date</th><th style="width:55%">Hours @ Level</th><th style="width:20%" align="right">Amount</th></tr>
"""

        var totalHours: Float = 0
        var totalFees: Float = 0
        var anyRateOverridden = false
        for fee in feeList {
            let rateDescription = fee.rateOverridden
                ? "\(judge.level.description) (" + String(format: "$%0.1f/hr, Rate Adjusted", fee.rate) + ")"
                : judge.level.fullDescription
            if fee.rateOverridden { anyRateOverridden = true }
            html += """
    <tr>
      <td>\(dateFormatterShort.string(from: fee.date))</td>
      <td>\(fee.getHours()) Hours @ \(rateDescription)</td>
      <td align="right">\(numberFormatter.string(from: NSNumber(value: fee.getFeeTotal())) ?? "$0.00")</td>
    </tr>
"""
            totalHours += fee.getHours()
            totalFees += fee.getFeeTotal()
        }

        if judge.isMeetRef() && judge.getMeetRefereeFee() > 0 {
            totalFees += judge.getMeetRefereeFee()
            html += """
    <tr>
      <td>&nbsp;</td>
      <td>Meet Referee Fee</td>
      <td align="right">\(numberFormatter.string(from: NSNumber(value: judge.getMeetRefereeFee())) ?? "$0.00")</td>
    </tr>
"""
        }

        let totalRateDescription = anyRateOverridden ? "\(judge.level.description) (Rate Adjusted)" : judge.level.fullDescription
        html += """
    <tr>
      <td colspan="3"><hr></td>
    </tr>
    <tr style="background-color:#EEEEEE">
      <td><strong>Total Fees</strong></td>
      <td><strong>\(totalHours) Hours @ \(totalRateDescription)</strong></td>
      <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: totalFees)) ?? "$0.00")</strong></td>
    </tr>
  </table>

  <h2 style="margin-top:8px; font-size:10pt;">Meet Expenses Summary</h2>
  <table class="expenses-table" border="1" cellpadding="2" cellspacing="0">
    <tr><th style="width:25%">Date</th><th style="width:55%">Expense Type</th><th style="width:20%" align="right">Amount</th></tr>
"""

        for expense in judge.expenses {
            if expense.getExpenseTotal() != 0 {
                var expenseTypeString = expense.type.description
                if expense.type == .Mileage {
                    expenseTypeString += "(\(expense.amount) miles @ \(numberFormatter.string(from: NSNumber(value: expense.mileageRate )) ?? "$0.00")/mile)"
                }
                if expense.type == .Lodging {
                    expenseTypeString += "(\(expense.totalNights ?? 0) night(s) @ \(numberFormatter.string(from: NSNumber(value: expense.amountPerNight ?? 0.0)) ?? "$0.00")/night)"
                }
                html += """
    <tr>
      <td>\(dateFormatterShort.string(from: expense.date!))</td>
      <td>\(expenseTypeString)</td>
      <td align="right">\(numberFormatter.string(from: NSNumber(value: expense.getExpenseTotal())) ?? "$0.00")</td>
    </tr>
"""
            }
        }

        html += """
    <tr>
      <td colspan="3"><hr></td>
    </tr>
    <tr style="background-color:#EEEEEE">
      <td colspan="2"><strong>Total Expenses</strong></td>
      <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: judge.totalExpenses())) ?? "$0.00")</strong></td>
    </tr>
    <tr>
      <td colspan="3"><hr></td>
    </tr>
    <tr style="background-color:#EEEEEE">
      <td colspan="2"><strong>Total Due</strong></td>
      <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: judge.totalCost())) ?? "$0.00")</strong></td>
    </tr>

    <tr>
      <td colspan="3">
        <table cellpadding="0" width="100%" border="0">
          <tr><td style="height:8px">&nbsp;</td></tr>
           <tr>
             <td style="width:55%"><hr></td>
             <td style="width:5%"></td>
             <td style="width:40%"><hr></td>
           </tr>
           <tr>
             <td>Signature</td>
             <td></td>
             <td>Date</td>
           </tr>
        </table>
      </td>
    </tr>
  </table>

</body>
</html>
"""

        return html
    }
}
