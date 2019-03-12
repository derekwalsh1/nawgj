//
//  JudgeListTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/21/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

/**
 This class is responsible for presenting the list of Judges.
 
 From this controller Judges can be:
 * Added
 * Removed
 * Edited
 
 
 */
class JudgeListTableViewController: UITableViewController {
    
    // This variable is set if the view controller is activated from the 'Add New Judge' segue
    var addingNewJudge : Bool = false
    
    // Judge Management can be done outside of the meet at the main window. This variable indicates that
    // Judge management is being done from there and so we should unwind to the main meet list
    var shouldUnwindToMeetList : Bool = false
    
    /*
     * Load the list of Judges from a persistent storage so that the table can be populated
     * when the view is presented
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        JudgeListManager.GetInstance().loadJudges()
    }
    
    /*
     * We save as we go so there is nothing to be performed here.
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    /*
     * We just have one section for the list of Judges in this table
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return JudgeListManager.GetInstance().judges!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeInfoCell", for: indexPath)
        
        // Fetches the appropriate meet for the data source layout.
        let judgeInfo = JudgeListManager.GetInstance().judges![indexPath.row]
        cell.textLabel?.textColor = self.view.tintColor
        cell.textLabel?.text = judgeInfo.name
        cell.detailTextLabel?.text = judgeInfo.level.fullDescription

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
            JudgeListManager.GetInstance().removeJudgeAt(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier! == "AddJudge"{
            // Create a New Judge named new Judge, if New Judge is already there then select that Judge
            let judgeInfo = JudgeInfo(name: "New Judge", level: Judge.Level.National)
            let judgeIndex = JudgeListManager.GetInstance().indexOfJudge(judgeInfo)
            if judgeIndex < 0{
                if JudgeListManager.GetInstance().addJudge(JudgeInfo(name: "New Judge", level: Judge.Level.National)){
                    let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
                    JudgeListManager.GetInstance().selectJudgeInfoAt(newIndexPath.row)
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                    self.addingNewJudge = true
                } else{
                    os_log("Didn't add judge %@", log: OSLog.default, type: .debug, judgeInfo.name)
                }
            } else{
                self.addingNewJudge = false
                JudgeListManager.GetInstance().selectJudgeInfoAt(judgeIndex)
            }
        }
        else{
            self.addingNewJudge = false
        }
        
        JudgeListManager.GetInstance().saveJudges()
    }
    
    //MARK: Actions
    @IBAction func unwindToJudgeInfoList(sender: UIStoryboardSegue) {
        JudgeListManager.GetInstance().loadJudges()
        tableView.reloadData()
        
        if addingNewJudge && !shouldUnwindToMeetList {
            self.performSegue(withIdentifier: "unwindFromJudgeList", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
        
        // If we came from the meet list then (because we should unwind to there) then segue
        // to the Judge details view so that the user can start editing Judge details.
        if shouldUnwindToMeetList{
            self.performSegue(withIdentifier: "ShowDetail", sender: self)
        }
        else{
            // This allows us to navigate back to the previous screen when a Judge is selected
            self.performSegue(withIdentifier: "unwindFromJudgeList", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
        self.performSegue(withIdentifier: "ShowDetail", sender: self)
    }
}
