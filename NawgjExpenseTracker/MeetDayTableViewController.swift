//
//  MeetDayTableViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDayTableViewController: UITableViewController {
    
    //MARK: Properties
    var meet : Meet?
    var formatter : DateFormatter = DateFormatter()
    var isIncorrectFirstDayDetected : Bool = false
    var areNonSequentialDaysDetected : Bool = false
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = MeetDay.DATE_FORMAT
        meet = MeetListManager.GetInstance().getSelectedMeet() ?? Meet(name: "", startDate: Date())
        checkForMeetDayWarnings()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            if let meet = meet {
                return meet.days.count
            }
            else{
                return 0
            }
        }
        else{
            var totalRows = 0
            if isIncorrectFirstDayDetected{
                totalRows+=1
            }
            
            if areNonSequentialDaysDetected{
                totalRows+=1
            }
            
            return 2//totalRows
        }
    }
        
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && (isIncorrectFirstDayDetected || areNonSequentialDaysDetected){
            return "We noticed some things..."
        }
        else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            // Configure the cell...
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableCell", for: indexPath)
            
            // Fetches the appropriate day for the data source layout.
            let meetDay = meet?.days[indexPath.row]
            cell.textLabel?.text = formatter.string(from: (meetDay?.meetDate)!)
            cell.detailTextLabel?.text = String(format: "%.2f Hours", (meetDay?.totalBillableTimeInHours())!)
            
            return cell
        }
        else{
            var cell : UITableViewCell!
            cell = tableView.dequeueReusableCell(withIdentifier: "WarningCell")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "WarningCell")
            }
            
            cell.selectionStyle = .none
            cell.imageView?.image = UIImage(systemName: "info.circle")
            if indexPath.row == 0 && isIncorrectFirstDayDetected{
                cell.textLabel?.text = "Date Mismatch"
                cell.detailTextLabel?.text = "Meet start date doesn't match earliest meet day"
            }
            else if indexPath.row == 1 && areNonSequentialDaysDetected{
                cell.textLabel?.text = "Non-Consequetive Days"
                cell.detailTextLabel?.text = "A gap was detected between one or more meet days"
            }
            else{
                cell.textLabel?.text = nil
                cell.detailTextLabel?.text = nil
            }
            
            return cell
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MeetListManager.GetInstance().removeMeetDayAt(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            checkForMeetDayWarnings()
            tableView.reloadData()
            self.loadViewIfNeeded()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1{
            if indexPath.row == 0 && isIncorrectFirstDayDetected{
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
            else if indexPath.row == 1 && areNonSequentialDaysDetected{
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
            else{
                return 0
            }
        }
        else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let destinationViewController = segue.destination as? MeetDayDetailViewController{
            destinationViewController.presentingInAddDayMode = segue.identifier == "AddItem"
        }
        
        switch(segue.identifier ?? "") {
            case "ShowDetail":
                if let selectedMeetDayCell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: selectedMeetDayCell){
                    MeetListManager.GetInstance().selectMeetDayAt(index: indexPath.row)
                }
            
            default:
                break
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetDayList(sender: UIStoryboardSegue) {
        checkForMeetDayWarnings()
        tableView.reloadData()
        self.loadViewIfNeeded()
    }
    
    func checkForMeetDayWarnings(){
        // 1. Make sure that the earliest meet day is the same as the meet start date
        // 2. Make sure all the meet days are in consequetive order
        isIncorrectFirstDayDetected = false
        areNonSequentialDaysDetected = false
        
        if let meet =  MeetListManager.GetInstance().getSelectedMeet(){
            if meet.days.count > 0 {
                let startDate = meet.startDate
                let days = meet.days.sorted(by: { $0.meetDate < $1.meetDate })
                isIncorrectFirstDayDetected = !Calendar.current.isDate(startDate, inSameDayAs: days[0].meetDate)
                
                if days.count > 1{
                    for i in 1...days.count - 1 {
                        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: days[i-1].meetDate)
                        areNonSequentialDaysDetected = nextDay != days[i].meetDate
                    }
                }
            }
        }
    }
}
