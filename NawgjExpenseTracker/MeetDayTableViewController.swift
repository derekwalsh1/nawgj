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
        meet = MeetListManager.GetInstance().getSelectedMeet() ?? Meet(name: "", startDate: Date())
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
            MeetListManager.GetInstance().removeMeetDayAt(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
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
        tableView.reloadData()
        self.loadViewIfNeeded()
    }
}
