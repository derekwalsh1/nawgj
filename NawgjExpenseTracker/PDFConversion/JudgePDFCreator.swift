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
        let html = generateJudgeInvoice(judge: judge, meet: meet)
        /*
        var html = generateHTMLHeader()
        html += generateJudgeFeesTable(judge: judge, meet: meet)
        html += generateJudgeExpensesTable(judge: judge, meet : meet)
        html += generateHTMLFooter()
        */
        
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = JudgeUIPrintPageRender(date: Date(), judge: judge, name: meet.name)
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
    
    static func generateJudgeInvoice(judge: Judge, meet: Meet) -> String{
        let paidCheckedString = judge.isPaid() ? "checked" : ""
        let w9CheckedString = judge.isW9Received() ? "checked" : ""
        let receiptsCheckedString = judge.isReceiptsReceived() ? "checked" : ""
        
        var html = """
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
              <table border="1" width="100%" height="100%" cellpadding="5" cellspacing="0">
                <tr height="200">
                  <td width="300" align="center">
                    <table width="100%" height="100%">
                      <tr height="75">
                        <td valign="center" align="center">
                          <strong><font size="6">\(judge.name)</font></strong>
                        </td>
                      </tr>
                      <tr height="25">
                        <td valign="top" align="center">\(judge.level.description)</td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table width="100%" height="100">
                      <tr>
                        <td>
                          Paid
                        </td>
                        <td><input type="checkbox" value="Paid" \(paidCheckedString) disabled></td>
                      </tr>
                      <tr>
                        <td>
                          W9 Received
                        </td>
                        <td><input type="checkbox" value="W9" \(w9CheckedString) disabled></td>
                      </tr>
                      <tr>
                        <td>
                          Receipts Received
                        </td>
                        <td>
                          <input type="checkbox" value="Receipts" \(receiptsCheckedString) disabled>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td valign="middle" width="400">
                    <strong>Notes:</strong><br>
                    \(judge.getNotes())
                  </td>
                </tr>
                <tr>
                  <td colspan="3">
                    <table cellspacing="5">
                      <tr>
                        <th width="150" align="left">Meet Name:</th>
                        <td>\(meet.name)</td>
                      </tr>
                      <tr>
                        <th align="left">Meet Dates:</th>
                        <td>12/23/2019 (Thursday), 12/24/2019 (Friday), 12/25/2019 (Saturday) and 12/26/2019 (Sunday)</td>
                      </tr>
                      <tr>
                        <th align="left">Meet Location:</th>
                        <td>\(meet.location)</td>
                      </tr>
                      <tr>
                        <th align="left">Meet Description:</th>
                        <td>\(meet.meetDescription)</td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr height="40">
                  <td colspan="3" align="center"><strong>Meet Fee Summary</strong></td>
                </tr>
                <tr>
                  <td valign="top" colspan="3">
                    <table width="100%" cellspacing="0">
                      <tr>
                        <th align="left" width="50px">Date</th>
                        <th align="left">Hours @ Level</th>
                        <th align="right">Amount</th>
                      </tr>
        """
        let feeList = judge.fees.sorted(by: {$0.date < $1.date})
        var totalHours : Float = 0
        var totalFees : Float = 0
        for fee in feeList{
            html += """
                <tr>
                    <td align="left">\(dateFormatterShort.string(from: fee.date))</td>
                    <td align="left">\(fee.getHours()) Hours @ \(judge.level.fullDescription)</td>
                    <td align="right">\(numberFormatter.string(from: NSNumber(value: fee.getFeeTotal())) ?? "$0.00")</td>
                </tr>
            """
            totalHours += fee.getHours()
            totalFees += fee.getFeeTotal()
        }
        
        if judge.isMeetRef() && judge.getMeetRefereeFee() > 0{
            totalFees += judge.getMeetRefereeFee()
            html += """
                <tr>
                    <td align="left">&nbsp;</td>
                    <td align="left">Meet Referee Fee</td>
                    <td align="right">\(numberFormatter.string(from: NSNumber(value: judge.getMeetRefereeFee())) ?? "$0.00")</td>
                </tr>
            """
        }
        
        html +=
            """
                      <tr>
                        <td colspan="3">
                          <hr>
                        </td>
                      </tr>
                      <tr bgcolor="lightgray">
                        <td align="left"><strong>Total Fees</strong></td>
                        <td align="left"><strong>\(totalHours) Hours @ \(judge.level.fullDescription)</strong></td>
                        <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: totalFees)) ?? "$0.00")</strong></td>
                      </tr>
        """
        html +=
            """
                    </table>
                  </td>
                </tr>
                <tr height="40">
                  <td colspan="3" align="center"><strong>Meet Expenses Summary</strong></td>
                </tr>
                <tr valign="top">
                  <td colspan="3">
                    <table width="100%" cellspacing="0">
                      <tr>
                        <th align="left" width="50px">Date</th>
                        <th align="left">Expense Type</th>
                        <th align="right">Amount</th>
                      </tr>
                      <tr>
                        <td align="left">12/23/2019</td>
                        <td align="left">Mileage 120 miles @ $0.58/mile</td>
                        <td align="right">$71.30</td>
                      </tr>
                      <tr>
                        <td align="left">12/23/2019</td>
                        <td align="left">Tolls</td>
                        <td align="right">$10.00</td>
                      </tr>
                      <tr>
                        <td align="left">12/23/2019</td>
                        <td align="left">Transportation</td>
                        <td align="right">$20.00</td>
                      </tr>
                      <tr>
                        <td align="left">12/23/2019</td>
                        <td align="left">Other</td>
                        <td align="right">$0.00</td>
                      </tr>
                      <tr>
                        <td colspan="3">
                          <hr>
                        </td>
                      </tr>
                      <tr bgcolor="lightgray">
                        <td colspan="2" align="left"><strong>Total Expenses</strong></td>
                        <td align="right"><strong>$101.03</strong></td>
                      </tr>
                      <tr>
                        <td colspan="3" align="left">
                          <hr>
                        </td>
                      </tr>
                      <tr bgcolor="lightgray">
                        <td colspan="2" align="left"><strong>Total Due</strong></td>
                        <td align="right"><strong>$959.03</strong></td>
                      </tr>
                      <tr valign="bottom" height="100%">
                        <td colspan="3" align="left">
                          <table cellpadding="0" width="100%" height="300" border="0">
                            <tr height="75%" valign="bottom">
                              <td colspan="3">&nbsp;</td>
                            </tr>
                            <tr valign="bttom" >
                              <td align="left" width="55%">
                                <hr>
                              </td>
                              <td width="5%"></td>
                              <td align="right" width="40%">
                                <hr>
                              </td>
                            </tr>
                            <tr valign="bottom">
                              <td align="left">Signature</td>
                              <td width></td>
                              <td align="left">Date</td>
                            </tr>
                        </td>
                      </tr>
                    </table>
                  </td>
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
