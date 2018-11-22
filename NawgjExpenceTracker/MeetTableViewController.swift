//
//  MeetTableViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/22/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetTableViewController: UITableViewController {
    
    //MARK: Properties
    
    var meets = [Meet]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Load any saved meets, otherwise load sample data.
        if let savedMeets = loadMeets() {
            meets += savedMeets
        }
        else{
            // Load the sample data.
            loadSampleMeets()
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
        return meets.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MeetTableViewCell", for: indexPath) as? MeetTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MeetTableViewCell.")
        }
        
        // Fetches the appropriate meet for the data source layout.
        let meet = meets[indexPath.row]
        cell.nameLabel.text = meet.name
        
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
            meets.remove(at: indexPath.row)
            saveMeets()
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
            os_log("Adding a new meet.", log: OSLog.default, type: .debug)
        case "ShowDetail":
            guard let meetDetailViewController = segue.destination as? MeetDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
                
            guard let selectedMeetCell = sender as? MeetTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
                
            guard let indexPath = tableView.indexPath(for: selectedMeetCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
                
            let selectedMeet = meets[indexPath.row]
            meetDetailViewController.meet = selectedMeet
            
        default:
            fatalError("Unexpected Segue Identifier; \(segue.identifier)")
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToMeetList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? MeetDetailViewController, let meet = sourceViewController.meet {
            
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
                // Update an existing meal.
                meets[selectedIndexPath.row] = meet
                tableView.reloadRows(at: [selectedIndexPath], with: .none)
            }
            else {
                // Add a new meet.
                let newIndexPath = IndexPath(row: meets.count, section: 0)
            
                meets.append(meet)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            // Save the meets
            saveMeets()
        }
    }
    
    //MARK: Private Methods
    
    private func loadSampleMeets() {
        var expenses = Array<Expense>()
        expenses.append(Expense(type: Expense.ExpenseType.Meals, amount: 45.0, notes: ""))
        expenses.append(Expense(type: Expense.ExpenseType.Other, amount: 300.34, notes: "Hotel Room"))
        expenses.append(Expense(type: Expense.ExpenseType.Toll, amount: 12.0, notes: "Hotel Room"))
        
        var judges = [Judge]()
        judges.append(Judge(name: "Judge 1", level: Judge.Level.National, expenses: expenses))
        judges.append(Judge(name: "Judge 2", level: Judge.Level.Brevet, expenses: expenses))
        judges.append(Judge(name: "Judge 3", level: Judge.Level.FourToEight, expenses: expenses))
        judges.append(Judge(name: "Judge 4", level: Judge.Level.Ten, expenses: expenses))
        
        var meetDays = Array<MeetDay>()
        meetDays.append(MeetDay(meetDate: Date(), startTime: Date(), endTime: Date().addingTimeInterval(TimeInterval(8.0*3600.0)), breaks: 3))
        meetDays.append(MeetDay(meetDate: Date(), startTime: Date(), endTime: Date().addingTimeInterval(TimeInterval(5.0*3600.0)), breaks: 2))
        meetDays.append(MeetDay(meetDate: Date(), startTime: Date(), endTime: Date().addingTimeInterval(TimeInterval(2.0*3600.0)), breaks: 1))
        
        guard let meet1 = Meet(name: "Reach for the Stars", days: meetDays, judges: judges, startDate: Date(), levels: [String]()) else {
            fatalError("Unable to instantiate meet1")
        }
        
        guard let meet2 = Meet(name: "Meet by the Bay", days: meetDays, judges: judges, startDate: Date(), levels: [String]()) else {
            fatalError("Unable to instantiate meet2")
        }
        
        guard let meet3 = Meet(name: "Flip to the Finish", days: meetDays, judges: judges, startDate: Date(), levels: [String]()) else {
            fatalError("Unable to instantiate meet3")
        }
        
        meets += [meet1, meet2, meet3]
    }
    
    private func saveMeets() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(meets, toFile: Meet.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Meets successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save meets...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadMeets() -> [Meet]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Meet.ArchiveURL.path) as? [Meet]
    }
    
    
}
