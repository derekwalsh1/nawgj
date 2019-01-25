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
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    //MARK: Properties
    var judge : Judge?
    var meet : Meet?
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit button item provided by the table view controller.
        dateFormatter.dateStyle = .full
        numberFormatter.numberStyle = .currency
        
        meet = MeetListManager.GetInstance().getSelectedMeet()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        
        if let judge = judge{
            backButton.title = judge.name
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
        return (judge?.fees.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeeTableViewCell", for: indexPath)
        
        // Fetches the appropriate meet for the data source layout.
        let fee = judge?.fees[indexPath.row]
        cell.textLabel?.text = dateFormatter.string(from: (fee?.date)!)
        cell.detailTextLabel?.text = String(format: "Hours: %0.2f - Total Fees: %@", (fee?.getHours())!, numberFormatter.string(from: fee!.getFeeTotal() as NSNumber)!)
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier) {
        case "ShowDetail":
            if let cell = sender as? UITableViewCell, let indexPath = tableView.indexPath(for: cell){
                MeetListManager.GetInstance().selectFeeAt(index: indexPath.row)
            }
        default:
            break
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToFeeList(sender: UIStoryboardSegue) {
        tableView.reloadData()
    }
}
