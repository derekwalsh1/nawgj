//
//  MeetViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDetailViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate{
    
    //MARK: Properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var meetDatePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var meetDateCell: UITableViewCell!
    @IBOutlet weak var meetLocationField: UITextField!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)` or constructed as part of adding a new meal.
     */
    var meet: Meet = Meet(name: "New Meet", startDate: Date())!
    var dateFormatter : DateFormatter = DateFormatter()
    var showMeetDatePicker : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        dateFormatter.dateStyle = .medium
        meetDateCell.textLabel?.textColor = self.view.tintColor
        meetDateCell.detailTextLabel?.text = dateFormatter.string(from: meet.startDate)
        
        // Set up views if editing an existing Meet.
        navigationItem.title = meet.name
        nameTextField.text = meet.name
        meetDatePicker.date = meet.startDate
        descriptionTextField.text = meet.meetDescription
        meetLocationField.text = meet.location
        
        // Enable the Save button only if the text field has a valid meet name.
        updateSaveButtonState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        switch indexPath.section {
        case 1:
            cell.detailTextLabel?.text = meetDaysDetailText()
        case 2:
            cell.detailTextLabel?.text = judgeDetailText()
        
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        switch(section){
        case 0:
            switch(row){
            case 3:
                showMeetDatePicker = !showMeetDatePicker
                tableView.beginUpdates()
                tableView.endUpdates()
            
            default:
                break
            }
        
        case 1:
            self.performSegue(withIdentifier: "ShowMeetDayTable", sender: self)
        case 2:
            self.performSegue(withIdentifier: "ShowJudgeTable", sender: self)

        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0 && (!showMeetDatePicker && indexPath.row == 4)) {
            return 0
        }
        else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the Save button while editing.
        saveButton.isEnabled = false
    }
    
    // MARK: Meet date selection
    
    @IBAction func meetDateChanged(_ sender: UIDatePicker) {
        meetDateCell.detailTextLabel?.text = dateFormatter.string(from: meetDatePicker.date)
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Discard Changes?", message: nil, preferredStyle: .alert)
        let actionCancel = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in }
        let actionDiscard = UIAlertAction(title: "Discard Changes", style: .default) { (action:UIAlertAction) in
            let isPresentingInAddMeetMode = self.presentingViewController is UINavigationController
            
            if isPresentingInAddMeetMode {
                self.dismiss(animated: true, completion: nil)
            }
            else if let owningNavigationController = self.navigationController{
                owningNavigationController.popViewController(animated: true)
            }
            else {
                fatalError("The MeetViewController is not inside a navigation controller.")
            }        }
        alert.addAction(actionCancel)
        alert.addAction(actionDiscard)
        self.present(alert, animated: true)
    }
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem{
            if button === saveButton {
                meet.name = nameTextField.text!
                meet.startDate = meetDatePicker.date
                meet.meetDescription = descriptionTextField.text!
                meet.location = meetLocationField.text!
            }
            else
            {
                return
            }
        }
        else{
            switch(segue.identifier ?? "") {
            
            case "ShowJudgeTable":
                guard let judgeTableViewController = segue.destination as? JudgeTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                judgeTableViewController.meet = meet
            
            case "ShowMeetDayTable":
                guard let meetDayTableViewController = segue.destination as? MeetDayTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                meet.startDate = meetDatePicker.date
                meetDayTableViewController.meet = meet
                
            default:
                fatalError("Unexpected Segue Identifier")
            }
        }
    }
    
    func meetDaysDetailText() -> String {
        let meetDayText = meet.days.count == 1 ? "Day" : "Days"
        return "\(meet.days.count) \(meetDayText) - \(meet.billableMeetHours()) Hours"
    }
    
    func judgeDetailText() -> String {
        let judgeText = meet.judges.count == 1 ? "Judge" : "Judges"
        return "\(meet.judges.count) \(judgeText) - " + String(format: "$%.2f", meet.totalJudgeFeesAndExpenses())
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetDetails(sender: UIStoryboardSegue) {
        
        let sourceViewController = sender.source as? MeetDayTableViewController
        let updatedMeet = sourceViewController?.meet
        
        if (sourceViewController != nil), (updatedMeet != nil){
            // Update an existing meet day.
            meet = updatedMeet!
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 1)).detailTextLabel?.text = meetDaysDetailText()
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 2)).detailTextLabel?.text = judgeDetailText()
        }
    }
    
    
    //MARK: Actions
    @IBAction func unwindToMeetDetailsFromJudgeList(sender: UIStoryboardSegue) {
        
        let sourceViewController = sender.source as? JudgeTableViewController
        let updatedMeet = sourceViewController?.meet
        
        if (sourceViewController != nil), (updatedMeet != nil){
            // Update an existing meet day.
            meet = updatedMeet!
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 2)).detailTextLabel?.text = judgeDetailText()
        }
    }
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
}

