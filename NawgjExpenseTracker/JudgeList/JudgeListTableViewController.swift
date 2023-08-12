//
//  JudgeListTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/21/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import os.log
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

/**
 This class is responsible for presenting the list of Judges.
 
 From this controller Judges can be:
 * Added
 * Removed
 * Edited
 
 
 */
class JudgeListTableViewController: UITableViewController, UIDocumentPickerDelegate {
    
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }
        else{
            return JudgeListManager.GetInstance().judges!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1{
            // Configure the cell...
            let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeInfoCell", for: indexPath)
            
            // Fetches the appropriate meet for the data source layout.
            let judgeInfo = JudgeListManager.GetInstance().judges![indexPath.row]
            cell.textLabel?.textColor = self.view.tintColor
            cell.textLabel?.text = judgeInfo.name
            cell.detailTextLabel?.text = judgeInfo.level.fullDescription

            return cell
        }
        else{
            return tableView.dequeueReusableCell(withIdentifier: "JudgeManagementCell", for: indexPath)
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return indexPath.section == 1
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
        if indexPath.section == 1{
            JudgeListManager.GetInstance().selectJudgeInfoAt(indexPath.row)
            self.performSegue(withIdentifier: "ShowDetail", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0{
            return 50
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    @IBAction func shareJudgeList(_ sender: UIButton) {
        self.share(sender: self.view)
    }
    
    @IBAction func importJudges(_ sender: UIButton) {
        var documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType] = [UTType.json]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: UIDocumentPickerMode.import)
        }
        documentPicker.delegate = self
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    
    @available(iOS 11.0, *)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
        JudgeListManager.GetInstance().importJudges(fromFile: urls.first)
        self.tableView.reloadData()
    }

    
    // called if the user dismisses the document picker without selecting a document (using the Cancel button)
    @available(iOS 8.0, *)
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController){
        
    }

    
    @available(iOS, introduced: 8.0, deprecated: 11.0)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    {
        JudgeListManager.GetInstance().importJudges(fromFile: url)
    }
    
    func dataToFile(fileName: String) -> URL? {
        do{
            let newURL = JudgeListManager.DocumentsDirectory.appendingPathComponent(fileName)
            let encodedData = try JSONEncoder().encode(JudgeListManager.GetInstance().judges)
            try encodedData.write(to: newURL)
            
            return newURL
        } catch{
            os_log("Failed to convert judges list to JSON format", log: OSLog.default, type: .error)
            return nil
        }
    }
    
    @objc func share(sender: UIView){
        if let file = dataToFile(fileName: "JudgeList.JSON")
        {
            let dataToShare = [file]
            
            let activityViewController = UIActivityViewController(activityItems: dataToShare, applicationActivities: nil)
            activityViewController.isModalInPresentation = true
            if let popOver = activityViewController.popoverPresentationController {
                popOver.sourceView = self.view
                popOver.sourceRect = sender.bounds
                popOver.permittedArrowDirections = []
                popOver.canOverlapSourceViewRect = true
            }
            
            self.present(activityViewController, animated: true, completion: nil)
        }
        else{
            os_log("No file returned from 'dataToFile' invocation", log: OSLog.default, type: .error)
        }
        
    }
}
