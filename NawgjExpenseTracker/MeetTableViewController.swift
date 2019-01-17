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
        
        // Load any saved meets, otherwise load sample data.
        if let savedMeets = loadMeets() {
            meets = savedMeets
            updateEditButton(false)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeetTableViewCell", for: indexPath) as! MeetTableViewCell
        
        // Fetches the appropriate meet for the data source layout.
        let meet = meets[indexPath.row]
        cell.meet = meet
        cell.setupCellContent()

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
            meets.remove(at: indexPath.row)
            saveMeets()
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEditButton(false)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class 
            // insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding a new meet.", log: OSLog.default, type: .debug)
            self.setEditing(false, animated: false)
                        
        case "ShowDetail":
            guard let meetDetailViewController = segue.destination as? MeetDetailViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
                
            guard let selectedMeetCell = sender as? UITableViewCell else {
                fatalError("Unexpected sender : sender is not a UITableViewCell")
            }
                
            guard let indexPath = tableView.indexPath(for: selectedMeetCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
                
            let selectedMeet = meets[indexPath.row]
            meetDetailViewController.meet = selectedMeet
            
        default:
            fatalError("Unexpected Segue Identifier")
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToMeetList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? MeetDetailViewController
        let meet = sourceViewController?.meet
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Update an existing meal.
            meets[selectedIndexPath.row] = meet!
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        }
        else {
            // Add a new meet.
            let newIndexPath = IndexPath(row: meets.count, section: 0)
            
            meets.append(meet!)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            updateEditButton(false)
        }
        
        // Save the meets
        saveMeets()
    }
    
    //MARK: Private Methods
    
    private func saveMeets() {
        meets.sort(by: {$0.startDate < $1.startDate})
        do{
            let encodedData = try JSONEncoder().encode(meets)
            try encodedData.write(to: Meet.ArchiveURL)
        } catch{
            os_log("Failed to save meets...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadMeets() -> [Meet]? {
        do{
            let data:Data = try Data(contentsOf: Meet.ArchiveURL)
            let jsonDecoder = JSONDecoder()
            return try! jsonDecoder.decode([Meet].self, from: data) as [Meet]
        } catch{
            os_log("Failed to load meets...", log: OSLog.default, type: .error)
            return Array<Meet>()
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool){
        super.setEditing(editing, animated: animated)
        updateEditButton(editing)
    }
    
    private func updateEditButton(_ editing: Bool){
        if self.tableView.numberOfRows(inSection: 0) < 1{
            self.navigationItem.leftBarButtonItem = nil
        }
        else{
            navigationItem.leftBarButtonItem = editButtonItem
        }
    }
}
