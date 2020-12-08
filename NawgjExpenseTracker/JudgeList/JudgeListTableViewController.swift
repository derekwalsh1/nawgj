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
    
    /*
     * Load the list of Judges from a persistent storage so that the table can be populated
     * when the view is presented
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        JudgeListManager.GetInstance().loadAndSortJudges()
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
       
        if let destinationViewController = segue.destination as? JudgeInfoDetailsTableViewController{
            if segue.identifier! == "AddJudge"{
                destinationViewController.addingNewJudge = true
            }
            else{
               destinationViewController.addingNewJudge = false
            }
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToJudgeInfoList(sender: UIStoryboardSegue) {
        JudgeListManager.GetInstance().loadAndSortJudges()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
        self.performSegue(withIdentifier: "ShowDetail", sender: self)
    }
    
    @IBAction func shareJudgeList(_ sender: UIBarButtonItem) {
        self.share(sender: self.view)
    }
    
    
    @objc func share(sender: UIView){
        
        let fileURL = JudgeListManager.ArchiveURL
        let newURL = JudgeListManager.DocumentsDirectory.appendingPathComponent("Judges.json")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: newURL.absoluteString){
            try! fileManager.removeItem(at: newURL)
        }
        
        if fileManager.isReadableFile(atPath: newURL.absoluteString){
            try! fileManager.removeItem(at: newURL)
        }
        
        try! fileManager.copyItem(at: fileURL, to: newURL)

        // Create the Array which includes the files you want to share
        var filesToShare = [Any]()

        // Add the path of the file to the Array
        filesToShare.append(newURL)

        // Make the activityViewContoller which shows the share-view
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        if let popOver = activityViewController.popoverPresentationController {
            popOver.sourceView = self.view
            popOver.sourceRect = sender.bounds
            popOver.permittedArrowDirections = []
            popOver.canOverlapSourceViewRect = true
        }
        // Show the share-view
        self.present(activityViewController, animated: true, completion: nil)
    }
}
