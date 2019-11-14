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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeetListManager.GetInstance().loadMeets()
        JudgeListManager.GetInstance().loadJudges()
        
        synchronizeJudgeList()
        updateEditButton(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeetListManager.GetInstance().meets!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: "MeetTableViewCell", for: indexPath) as! MeetTableViewCell
        
        // Fetches the appropriate meet for the data source layout.
        let meet = MeetListManager.GetInstance().meets![indexPath.row]
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
            MeetListManager.GetInstance().removeMeetAt(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEditButton(false)
        } 
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //let movedObject = self.headlines[sourceIndexPath.row]
        //headlines.remove(at: sourceIndexPath.row)
        //headlines.insert(movedObject, at: destinationIndexPath.row)
        MeetListManager.GetInstance().moveMeet(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            os_log("Adding a new meet.", log: OSLog.default, type: .debug)
            let meet = Meet(name: "New Meet", startDate: Date())
            let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            MeetListManager.GetInstance().addMeet(meet: meet!)
            MeetListManager.GetInstance().selectMeetAt(index: newIndexPath.row)
            MeetListManager.GetInstance().saveMeets()
            
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            updateEditButton(false)
            self.setEditing(false, animated: false)
                        
        case "ShowDetail":
            guard let selectedMeetCell = sender as? UITableViewCell else {
                fatalError("Unexpected sender : sender is not a UITableViewCell")
            }
                
            guard let indexPath = tableView.indexPath(for: selectedMeetCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
                
            MeetListManager.GetInstance().selectMeetAt(index: indexPath.row)
        case "showJudgesFromMeetList":
            break
        default:
            break
        }
    }

    @IBAction func unwindFromJudgeListWithSender(sender: UIStoryboardSegue){
        self.unwindToMeetList(sender: sender)
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetList(sender: UIStoryboardSegue) {
        MeetListManager.GetInstance().loadMeets()
        self.tableView.reloadData()
    }
    
    //MARK: Private Methods
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
    
    func synchronizeJudgeList(){
        // In case someone has used an older version of the app, go through the list of meets and add any existing judges. If a judge
        // appears in a meet that is not in the judge list, then add the judge and save the list
        if let meets = MeetListManager.GetInstance().meets{
            for meet in meets{
                for meetJudge in meet.judges{
                    let judgeInfo = JudgeInfo(name: meetJudge.name, level: meetJudge.level)
                    if JudgeListManager.GetInstance().addJudge(judgeInfo){
                        os_log("Added Judge %@", log: OSLog.default, type: .debug, judgeInfo.name)
                    } else{
                        os_log("Judge %@ not added because they already exist in the Judge List", log: OSLog.default, type: .debug, judgeInfo.name)
                    }
                }
            }
        }
    }
}
