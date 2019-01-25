//
//  JudgeListTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/21/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeListTableViewController: UITableViewController {
    
    var addingNewJudge : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        JudgeListManager.GetInstance().loadJudges()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
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
            JudgeListManager.GetInstance().addJudge(JudgeInfo(name: "New Judge", level: Judge.Level.FourToEight))
            
            let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            JudgeListManager.GetInstance().selectJudgeInfoAt(newIndexPath.row)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
            self.addingNewJudge = true
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
        
        if addingNewJudge{
            self.performSegue(withIdentifier: "unwindToJudgeDetails", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
        self.performSegue(withIdentifier: "unwindToJudgeDetails", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
        self.performSegue(withIdentifier: "ShowDetail", sender: self)
    }
}
