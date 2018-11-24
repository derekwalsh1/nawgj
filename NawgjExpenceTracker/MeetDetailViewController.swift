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
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var meet: Meet = Meet(name: "New Meet", days: Array<MeetDay>(), judges: Array<Judge>(), startDate: Date(), levels: Array<String>())!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        
        // Set up views if editing an existing Meal.
        navigationItem.title = meet.name
        nameTextField.text = meet.name
        
        
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        switch(section){
        case 0:
            switch(row){
            case 3:
                self.performSegue(withIdentifier: "ShowMeetDayTable", sender: self)
            case 4:
                self.performSegue(withIdentifier: "ShowJudgeTable", sender: self)
            default:
                break
            }
        
        case 1:
            break
            
        default: break
            
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
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        let isPresentingInAddMeetMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMeetMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MeetViewController is not inside a navigation controller.")
        }
    }
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // TODO : Add another 2 options here
        // We can seque to editing the meet days or editing the judges or back to the meet table
        // or
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem{
            if button === saveButton {
                meet.name = nameTextField.text!
/*                let days = [MeetDay]()
                let judges = [Judge]()
                let startDate = Date()
                let levels = [String]()
                
                // Set the meet to be passed to MeetTableViewController after the unwind segue.
                meet = Meet(name: name!, days: days, judges: judges, startDate: startDate, levels: levels)*/
                return
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
                
                meetDayTableViewController.meet = meet
                
            default:
                fatalError("Unexpected Segue Identifier; \(segue.identifier)")
            }
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetDetails(sender: UIStoryboardSegue) {
        
        let sourceViewController = sender.source as? MeetDayTableViewController
        let updatedMeet = sourceViewController?.meet
        
        if (sourceViewController != nil), (updatedMeet != nil){
            // Update an existing meet day.
            meet = updatedMeet!
        }
    }
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
}

