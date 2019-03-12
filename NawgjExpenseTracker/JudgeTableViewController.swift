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
    var numberFormatter : NumberFormatter = NumberFormatter()
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        meet = MeetListManager.GetInstance().getSelectedMeet()
        meet!.judges = (meet?.judges.sorted(by: {$0.name < $1.name}))!
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
        let prefix = (judge?.isPaid())! ? "✓ " : " "
        cell.textLabel?.text = prefix + (judge?.name)! + " (\(judge!.level.description))"
        cell.detailTextLabel?.text = String(format: " Fees: %@ | Expenses: %@", numberFormatter.string(from: judge!.totalFees() as NSNumber)!, numberFormatter.string(from: judge!.totalExpenses() as NSNumber)!)
        
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
            meet?.judges.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class
            // insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            let newJudge = Judge(name: "New Judge", level: .FourToEight, fees: Array<Fee>())!
            let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            MeetListManager.GetInstance().addJudge(judge: newJudge)
            MeetListManager.GetInstance().selectJudgeAt(index: newIndexPath.row)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
        case "ShowDetail":
            guard let selectedJudgeCell = sender as? JudgeTableViewCell, let indexPath = tableView.indexPath(for: selectedJudgeCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            MeetListManager.GetInstance().selectJudgeAt(index: indexPath.row)
            
        default:
            break
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToJudgeList(sender: UIStoryboardSegue) {
        tableView.reloadData()
    }
}
