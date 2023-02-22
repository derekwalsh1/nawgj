//
//  JudgeFeesAndExpensesSummaryTableView.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/3/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit

class JudgeSummaryTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var meet : Meet
    var judge : Judge
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    init(judge: Judge, meet: Meet){
        self.judge = judge
        self.meet = meet
        self.dateFormatter.dateStyle = .long
        self.numberFormatter.numberStyle = .currency
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return judge.fees.count + 1 // additional row for total
        default:
            return judge.expenses.count + 2 // additional rows for totals
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeSummaryCell")!
        
        switch indexPath.section {
        case 0:
            switch indexPath.row{
            case judge.fees.count:
                cell.textLabel?.text = "Total Fees"
                cell.textLabel?.textColor = tableView.tintColor
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: (cell.textLabel?.font.pointSize)!)
                cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: judge.totalFees() as NSNumber)!)
                cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
            default:
                let fee = judge.fees[indexPath.row]
                cell.textLabel?.textColor = UIColor.label
                cell.textLabel?.text = dateFormatter.string(from: fee.date)
                cell.textLabel?.font = UIFont.systemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
                cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: fee.getFeeTotal() as NSNumber)!)
                cell.detailTextLabel?.textColor = UIColor.label
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
            }
            
        default:
            switch indexPath.row{
            case judge.expenses.count:
                cell.textLabel?.text = "Total Expenses"
                cell.textLabel?.textColor = tableView.tintColor
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: (cell.textLabel?.font.pointSize)!)
                cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: judge.totalExpenses() as NSNumber)!)
                cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
            case judge.expenses.count + 1:
                cell.textLabel?.text = "Total Fees & Expenses"
                cell.textLabel?.textColor = tableView.tintColor
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: (cell.textLabel?.font.pointSize)!)
                cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: (judge.totalExpenses() + judge.totalFees()) as NSNumber)!)
                cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
            default:
                let expense = judge.expenses[indexPath.row]
                cell.textLabel?.textColor = UIColor.label
                cell.textLabel?.text = expense.type.description
                cell.textLabel?.font = UIFont.systemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
                cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!)
                cell.detailTextLabel?.textColor = UIColor.label
                cell.detailTextLabel?.font = UIFont.systemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
            }
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Judge Fees"
        default:
            return "Judge Expenses"
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return " "
    }
}
