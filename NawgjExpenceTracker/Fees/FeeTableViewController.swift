//
//  FeeTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class FeeTableViewController: UITableViewController {
    
    //MARK: Properties
    var judge : Judge?
    var meet : Meet?
    var dateFormatter : DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        dateFormatter.dateStyle = .medium
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
        return (judge?.fees.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeeTableViewCell", for: indexPath)
        
        // Fetches the appropriate meet for the data source layout.
        let fee = judge?.fees[indexPath.row]
        cell.textLabel?.text = dateFormatter.string(from: (fee?.date)!)
        cell.detailTextLabel?.text = String(format: "Hours: %0.2f - Total Fees: $%0.2f", (fee?.hours)!, (fee?.hours)! * (judge?.level.rate)!)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "Unwind") {
        case "ShowDetail":
            guard let feeDetailsViewController = segue.destination as? FeeDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedFeeCell = sender as? UITableViewCell else {
                fatalError("Unexpected sender : sender is not a UITableViewCell")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedFeeCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedFee = judge?.fees[indexPath.row]
            let meetDay = meet?.days[(meet?.days.index(where: {$0.meetDate == selectedFee?.date}))!]
            feeDetailsViewController.fee = selectedFee!
            feeDetailsViewController.judge = judge
            feeDetailsViewController.meetDay = meetDay
        case "Unwind":
            break
        default:
            fatalError("Unexpected Segue Identifier - \(segue.identifier!)")
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToFeeList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? FeeDetailsViewController
        let fee = sourceViewController?.fee
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Update an existing meal.
            judge?.fees[selectedIndexPath.row] = fee!
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        }
    }
}

