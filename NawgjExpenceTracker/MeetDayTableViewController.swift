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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = MeetDay.DATE_FORMAT
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
        return (meet?.days.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MeetDayTableCell", for: indexPath) as? MeetDayTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MeetDayTableViewCell.")
        }
        
        // Fetches the appropriate day for the data source layout.
        let meetDay = meet?.days[indexPath.row]
        cell.nameLabel.text = formatter.string(from: (meetDay?.meetDate)!)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meet?.days.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class
            // insert it into the array, and add a new row to the table view
        }
    }
    
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding a new meet day.", log: OSLog.default, type: .debug)
        case "ShowDetail":
            guard let meetDayDetailViewController = segue.destination as? MeetDayDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedMeetDayCell = sender as? MeetDayTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedMeetDayCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let meetDay = meet?.days[indexPath.row]
            meetDayDetailViewController.meetDay = meetDay
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
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
                
                meet?.days.append(meetDay!)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
    }
}
