//
//  JudgeTableViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/16/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeTableViewController: UITableViewController {
    
    //MARK: Properties
    var meet : Meet?
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        return (meet?.judges.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeTableCell", for: indexPath) as? JudgeTableViewCell  else {
            fatalError("The dequeued cell is not an instance of JudgeTableViewCell.")
        }
        
        // Fetches the appropriate meet for the data source layout.
        let judge = meet?.judges[indexPath.row]
        cell.nameLabel.text = judge?.name
        
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
            meet?.judges.remove(at: indexPath.row)
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
        
        if let button = sender as? UIBarButtonItem, button === doneButton {
            return
        }
        else{
            
            switch(segue.identifier ?? "") {
            case "AddItem":
                os_log("Adding a new judge.", log: OSLog.default, type: .debug)
            case "ShowDetail":
                guard let judgeDetailViewController = segue.destination as? JudgeDetailViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                guard let selectedJudgeCell = sender as? JudgeTableViewCell else {
                    fatalError("Unexpected sender: Sender is not a JudgeTableViewCell")
                }
                
                guard let indexPath = tableView.indexPath(for: selectedJudgeCell) else {
                    fatalError("The selected cell is not being displayed by the table")
                }
                
                let judge = meet?.judges[indexPath.row]
                judgeDetailViewController.judge = judge
                
            default:
                fatalError("Unexpected Segue Identifier")
            }
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToJudgeList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? JudgeDetailViewController
        let judge = sourceViewController?.judge
        
        if (sourceViewController != nil), (judge != nil) {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                
                // Update an existing meal.
                meet?.judges[selectedIndexPath.row] = judge!
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new meet.
                let newIndexPath = IndexPath(row: (meet?.judges.count)!, section: 0)
                
                meet?.judges.append(judge!)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
        }
    }
}
