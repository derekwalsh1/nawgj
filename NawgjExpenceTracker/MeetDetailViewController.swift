//
//  MeetViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDetailViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var meet: Meet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        tableView.delegate = self
        
        // Set up views if editing an existing Meal.
        if let meet = meet {
            navigationItem.title = meet.name
            nameTextField.text   = meet.name
        }
        
        tableView.dataSource = self
        
        // Enable the Save button only if the text field has a valid meet name.
        updateSaveButtonState()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK : UI Table View Data Source
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeSummaryViewCell", for: indexPath)
        switch indexPath.section
        {
        case 0:
            cell.textLabel?.text = "Meet Days"
        case 1:
            cell.textLabel?.text = "Judges"
        default:
            cell.textLabel?.text = "Unknown"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    //MARK: UITableViewDelegate
    
    /*
     Two sections, 1 for the cell that links to the list of judges and one for the cell that
     links to the list of days that the meet is on for.
     */
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        switch(section){
        case 0:
            self.performSegue(withIdentifier: "ShowMeetDayTable", sender: self)
        case 1:
            self.performSegue(withIdentifier: "ShowJudgeTable", sender: self)
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
                let name = nameTextField.text ?? ""
                let days = [MeetDay]()
                let judges = [Judge]()
                let startDate = Date()
                let levels = [String]()
                
                // Set the meet to be passed to MeetTableViewController after the unwind segue.
                meet = Meet(name: name, days: days, judges: judges, startDate: startDate, levels: levels)
            }
            else
            {
                return
            }
        }
        else{
            switch(segue.identifier ?? "") {
            case "AddItem":
                os_log("Adding a new meet.", log: OSLog.default, type: .debug)
            case "ShowJudgeTable":
                guard let judgeDetailViewController = segue.destination as? JudgeTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                judgeDetailViewController.meet = meet
            case "ShowMeetDayTable":
                guard let meetDayDetailViewController = segue.destination as? MeetDayTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                meetDayDetailViewController.meet = meet

                
            default:
                fatalError("Unexpected Segue Identifier; \(segue.identifier)")
            }
        }
    }
    
    //MARK: Actions
    
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        let text = nameTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
}

