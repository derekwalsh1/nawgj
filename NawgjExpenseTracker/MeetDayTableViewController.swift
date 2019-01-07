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
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = MeetDay.DATE_FORMAT
        
        if meet == nil{
            meet = Meet(name: "", startDate: Date())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let meet = meet {
            return meet.days.count
        }
        else{
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableCell", for: indexPath)
        
        
        // Fetches the appropriate day for the data source layout.
        let meetDay = meet?.days[indexPath.row]
        cell.textLabel?.text = formatter.string(from: (meetDay?.meetDate)!)
        cell.detailTextLabel?.text = String(format: "%.2f Hours", (meetDay?.totalBillableTimeInHours())!)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meet?.removeMeetDay(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class
            // insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        if let button = sender as? UIBarButtonItem, button === doneButton {
            return
        }
        else{
            switch(segue.identifier ?? "") {
            case "AddItem":
                os_log("Adding a new meet day.", log: OSLog.default, type: .debug)
                
                // If any existing meet days have been defined, then add a new item using the 
                // date from the previous day to setup the date for the next day otherwise use the meet start date
                let destinationNavigationController = segue.destination as! UINavigationController
                guard let meetDayDetailViewController = destinationNavigationController.topViewController as? MeetDayDetailViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                meetDayDetailViewController.meet = meet
                
                if (meet?.days.count)! > 0 {
                    let nextMeetDay = MeetDay(meetDate: Date(), startTime: Date(), endTime: Date(), breaks: 2)
                    let previousMeetDay = meet?.days[(meet?.days.count)! - 1]
                    nextMeetDay.breaks = (previousMeetDay?.breaks)!
                    nextMeetDay.meetDate = (previousMeetDay?.meetDate.addingTimeInterval(24*60*60))!
                    nextMeetDay.startTime = (previousMeetDay?.startTime)!
                    nextMeetDay.endTime = (previousMeetDay?.endTime)!
                    
                    
                    meetDayDetailViewController.meetDay = nextMeetDay
                }
                else{
                    let date = meet?.startDate
                    let startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date!)
                    let endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: date!)
                    let firstMeetDay = MeetDay(meetDate: date!, startTime: startTime!, endTime: endTime!, breaks: 2)
                    meetDayDetailViewController.meetDay = firstMeetDay
                }
                
            case "ShowDetail":
                guard let meetDayDetailViewController = segue.destination as? MeetDayDetailViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                guard let selectedMeetDayCell = sender as? UITableViewCell else {
                    fatalError("Unexpected sender - Expected UITableViewCell")
                }
                
                guard let indexPath = tableView.indexPath(for: selectedMeetDayCell) else {
                    fatalError("The selected cell is not being displayed by the table")
                }
                
                let meetDay = meet?.days[indexPath.row]
                meetDayDetailViewController.meetDay = meetDay
                meetDayDetailViewController.meet = meet
                
            default:
                fatalError("Unexpected Segue Identifier")
            }
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToMeetDayList(sender: UIStoryboardSegue) {
        
        let sourceViewController = sender.source as? MeetDayDetailViewController
        let meetDay = sourceViewController?.meetDay
        
        if (sourceViewController != nil), (meetDay != nil){
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                
                // Update an existing meet day.
                meet?.days[selectedIndexPath.row] = meetDay!
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new meet day.
                let newIndexPath = IndexPath(row: (meet?.days.count)!, section: 0)
                
                meet?.addMeetDay(day: meetDay!)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
    }
}
