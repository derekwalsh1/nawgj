//
//  AddJudgeViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek Walsh on 10/25/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class AddJudgeFromInsideMeetTableViewController: UITableViewController {
    
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Two sections, the first displays the components needed to add a new
        // judge. The second displays the components needed to select judges to
        // add to the meet.
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            // Return the same number of cells as there are judges
            return JudgeListManager.GetInstance().judges!.count
        }
        else{
            // First cell is for entering the Judge's name
            // Second cell is for selecting the Judge's level
            return 2
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        // Check which button was clicked before performing the segue and update
        // the meet details as necessary
        if let barButtonItem = sender as? UIBarButtonItem {
            
            // Update the list of judges associated with this meet with
            // the list of selected judges.
            
            if barButtonItem.title == "Done"{
                os_log("Done button clicked", log: OSLog.default, type: .info)
            }
            else if barButtonItem.title == "Cancel"{
                os_log("Cancel button clicked", log: OSLog.default, type: .info)
            }
            else{
                os_log("Unhandled button clicked", log: OSLog.default, type: .info)
            }
            
        }
    }
    
}
