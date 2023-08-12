//
//  MeetSummaryTableDelegate.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/7/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit

class MeetSummaryTableViewDelegate: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    var meet : Meet
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    init(meet: Meet){
        self.meet = meet
        self.dateFormatter.dateStyle = .long
        self.numberFormatter.numberStyle = .currency
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meet.judges.count + 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return meet.days.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeFeeSummaryCell")!
        
        switch indexPath.row{
        case meet.judges.count:
            cell.textLabel?.text = "Total Day Fees"
            cell.textLabel?.textColor = tableView.tintColor
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: (cell.textLabel?.font.pointSize)!)
            cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: meet.totalJudgesFeeForDay(dayIndex: indexPath.section) as NSNumber)!)
            cell.detailTextLabel?.font = UIFont.boldSystemFont(ofSize: (cell.detailTextLabel?.font.pointSize)!)
        default:
            let judge = meet.judges[indexPath.row]
            cell.textLabel?.text = String(format: "%@ (%@)", judge.name, judge.level.description)
            cell.textLabel?.textColor = nil
            cell.textLabel?.font = nil
            cell.detailTextLabel?.text = String(format: "%@", numberFormatter.string(from: meet.judgesFeeForDay(dayIndex: indexPath.section, judge: meet.judges[indexPath.row]) as NSNumber)!)
            cell.detailTextLabel?.font = nil
        }
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(format: "%@ (%0.2f Hours)", dateFormatter.string(from: meet.days[section].meetDate), meet.days[section].totalBillableTimeInHours())
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return " "
    }
}
