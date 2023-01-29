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
        let feeList = judge.fees.sorted(by: {$0.date < $1.date})
        
        var datesString = ""
        
        if feeList.count > 0{
            for index in 0...feeList.count - 1{
                datesString.append(dateFormatter.string(from: feeList[index].date))
                if index < (feeList.count - 1){
                    datesString.append("<br>")
                }
            }
        }
        
        var html = """
            <html>
            <head>
              <style type="text/css">
                @media print {
                .pagebreak-before:first-child { display: block; page-break-before: avoid; }
                .pagebreak-before { display: block; page-break-before: always; }
                }
            .container {
                  display: block;
                  position: relative;
                  padding-left: 35px;
                  margin-bottom: 12px;
                  cursor: pointer;
                  font-size: 19px;
                  -webkit-user-select: none;
                  -moz-user-select: none;
                  -ms-user-select: none;
                  user-select: none;
                }

                /* Hide the browser's default checkbox */
                .container input {
                  position: absolute;
                  opacity: 0;
                  cursor: pointer;
                  height: 0;
                  width: 0;
                }

                /* Create a custom checkbox */
                .checkmark {
                  position: absolute;
                  top: 0;
                  left: 0;
                  height: 25px;
                  width: 25px;
                  background-color: #eee;
                }

                /* On mouse-over, add a grey background color */
                .container:hover input ~ .checkmark {
                  background-color: #ccc;
                }

                /* When the checkbox is checked, add a blue background */
                .container input:checked ~ .checkmark {
                  background-color: rgb(77, 86, 94);
                }

                /* Create the checkmark/indicator (hidden when not checked) */
                .checkmark:after {
                  content: "";
                  position: absolute;
                  display: none;
                }

                /* Show the checkmark when checked */
                .container input:checked ~ .checkmark:after {
                  display: block;
                }

                /* Style the checkmark/indicator */
                .container .checkmark:after {
                  left: 9px;
                  top: 5px;
                  width: 5px;
                  height: 10px;
                  border: solid white;
                  border-width: 0 3px 3px 0;
                  -webkit-transform: rotate(45deg);
                  -ms-transform: rotate(45deg);
                  transform: rotate(45deg);
                }
                .large {
                  font-size: 22px; /* font-size 1em = 10px on default browser settings */
                }
              </style>
            </head>
            <body>
              <table class="large" border="1" width="100%" height="100%" cellpadding="5" cellspacing="0">
                <tr height="200">
                  <td width="300" align="center">
                    <table width="100%" height="100%" cellpadding="10">
                      <tr height="75">
                        <td valign="top" align="center">
                          <strong><font size="6">\(judge.name)</font></strong>
                        </td>
                      </tr>
                      <tr height="25">
                        <td class="large" valign="top" align="center">\(judge.level.description)</td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table class="large" width="100%" height="100">
                      <tr>
                        <td width="30">&nbsp;</td>
                        <td>
                            <label class="container">Paid
                                <input type="checkbox" \(paidCheckedString) disabled>
                                <span class="checkmark"></span>
                              </label>
                        </td>
                      </tr>
                      <tr>
                        <td>&nbsp;</td>
                        <td>
                            <label class="container">W9 Received
                                <input type="checkbox" \(w9CheckedString) disabled>
                                <span class="checkmark"></span>
                              </label>
                        </td>
                      </tr>
                      <tr>
                        <td>&nbsp;</td>
                        <td>
                            <label class="container">Receipts Received
                                <input type="checkbox" \(receiptsCheckedString) disabled>
                                <span class="checkmark"></span>
                              </label>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td valign="top" width="400">
                    <table class="large" cellpadding="10">
                        <tr><td>
                            <strong>Notes:</strong><br>
                            \(judge.getNotes())
                        </td></tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <td colspan="3">
                    <table class="large" cellspacing="5">
                      <tr>
                        <th width="150" align="left">Meet Name:</th>
                        <td>\(meet.name)</td>
                      </tr>
                      <tr valign="top">
                        <th align="left">Meet Dates:</th>
                        <td>\(datesString)</td>
                      </tr>
                      <tr>
                        <th align="left">Meet Location:</th>
                        <td>\(meet.location)</td>
                      </tr>
                      <tr>
                        <th align="left">Meet Description:</th>
                        <td>\(meet.meetDescription)</td>
                      </tr>
                        <tr>
                          <th align="left">Mileage Rate:</th>
                          <td>\(meet.getMileageRate())</td>
                        </tr>
                    </table>
                  </td>
                </tr>
                <tr height="40">
                  <td colspan="3" align="center"><strong>Meet Fee Summary</strong></td>
                </tr>
                <tr>
                  <td valign="top" colspan="3">
                    <table class="large" width="100%" cellspacing="0">
                      <tr>
                        <th align="left" width="50px">Date</th>
                        <th align="left">Hours @ Level</th>
                        <th align="right">Amount</th>
                      </tr>
        """
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
                    <table class="large" width="100%" cellspacing="0">
                    <tr>
                      <th align="left">Date</th>
                      <th align="left">Expense Type</th>
                      <th align="right">Amount</th>
                    </tr>
        
        """
        
        for expense in judge.expenses{
            if expense.amount > 0{
                var expenseTypeString = expense.type.description
                if expense.type == .Mileage{
                    expenseTypeString += "(\(expense.amount) miles @ \(numberFormatter.string(from: NSNumber(value: meet.getMileageRate())) ?? "$0.00")/mile)"
                }
                
                html += """
                    <tr>
                        <td align="left">\(dateFormatterShort.string(from: expense.date!))</th>
                        <td align="left">\(expenseTypeString)</th>
                        <td align="right">\(numberFormatter.string(from: NSNumber(value: expense.getExpenseTotal())) ?? "$0.00")</th>
                    </tr>
                    """
            }
        }
        
        html += """
                      <tr>
                        <td colspan="3">
                          <hr>
                        </td>
                      </tr>
                      <tr bgcolor="lightgray">
                        <td colspan="2" align="left"><strong>Total Expenses</strong></td>
                        <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: judge.totalExpenses())) ?? "$0.00")</strong></td>
                      </tr>
                      <tr>
                        <td colspan="3" align="left">
                          <hr>
                        </td>
                      </tr>
                      <tr bgcolor="lightgray">
                        <td colspan="2" align="left"><strong>Total Due</strong></td>
                        <td align="right"><strong>\(numberFormatter.string(from: NSNumber(value: judge.totalCost())) ?? "$0.00")</strong></td>
                      </tr>
                      <tr valign="bottom" height="100%">
                        <td colspan="3" align="left">
                          <table class="large" cellpadding="0" width="100%" border="0">
                            <tr height="75%" valign="bottom">
                              <td colspan="3">&nbsp;</td>
                            </tr>
                            <tr valign="bottom">
                              <td align="left">&nbsp;</td>
                              <td>&nbsp;</td>
                              <td align="left">&nbsp;</td>
                            </tr>
                            <tr valign="bottom" >
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
