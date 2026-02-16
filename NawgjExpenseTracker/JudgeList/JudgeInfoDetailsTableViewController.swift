//
//  JudgeInfoDetailsTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/23/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

/// Manages the judge info detail form for adding or editing a judge.
///
/// This controller coordinates the name field, the level picker, and the save/cancel
/// actions. It uses `JudgeListManager` for persistence and validates input to prevent
/// duplicate judge entries when creating new judges.
class JudgeInfoDetailsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    /// Text field for the judge's display name.
    @IBOutlet weak var nameTextField: UITextField!
    /// Picker for selecting the judge level (USAG/NGA variants).
    @IBOutlet weak var levelPicker: UIPickerView!
    /// Cell that displays the currently selected level description.
    @IBOutlet weak var levelCell: UITableViewCell!
    /// Label used to style the name prompt.
    @IBOutlet weak var nameLabel: UILabel!
    /// Save button enabled only when input is valid.
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    /// Whether the level picker row should be visible.
    var showPicker : Bool = false
    /// Whether the screen is creating a new judge rather than editing one.
    var addingNewJudge : Bool = false
    
    /// Configures delegates, initial form state, and default values.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameTextField.delegate = self
        levelPicker.dataSource = self
        levelPicker.delegate = self
        saveButton.isEnabled = false
        
        if addingNewJudge{
            // Well we have no information so let's populate the UI with some default
            nameTextField.text = nil
            let defaultLevel = Judge.Level.count > 1 ? Judge.Level.count - 2 : 0
            levelPicker.selectRow(defaultLevel, inComponent: 0, animated: false)
            levelCell.detailTextLabel?.text = Judge.Level(rawValue: defaultLevel)?.description
            self.navigationItem.title = "Adding Judge Info"
        }
        else{
            if let judgeInfo = JudgeListManager.GetInstance().selectedJudge{
                nameTextField.text = judgeInfo.name
                levelCell.detailTextLabel!.text = judgeInfo.level.fullDescription
                levelPicker.selectRow(judgeInfo.level.rawValue, inComponent: 0, animated: false)
                
                saveButton.isEnabled = true
                self.navigationItem.title = judgeInfo.name
            }
        }
        
        nameLabel?.textColor = self.view.tintColor
        levelCell.textLabel?.textColor = self.view.tintColor
        
        nameTextField.becomeFirstResponder()
        updateSaveButtonState()
    }
    
    /// Called when the name field ends editing; restores previous name if empty.
    @IBAction func nameEditingEnded(_ sender: UITextField) {
        updateNameField()
    }
    
    /// Dismisses the keyboard when the return key is pressed.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /// Updates save button state when editing begins.
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
    /// Updates the name field and save button when editing ends.
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateNameField()
    }
    
    /// Ensures the name field is not left empty when editing an existing judge.
    func updateNameField(){
        if let text = nameTextField.text{
            if !addingNewJudge && text.isEmpty{
                if let selectedJudge = JudgeListManager.GetInstance().selectedJudge{
                    nameTextField.text = selectedJudge.name
                }
            }
        }
    }
    
    //MARK: UIPickerView
    /// Single column picker for judge level selection.
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// Number of levels shown in the picker.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Judge.Level.count
    }
    
    /// Displays the level description for each picker row.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let level = Judge.Level(rawValue: row)!
        return level.description;
    }
    
    /// Updates the level display when a new row is selected.
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        levelCell.detailTextLabel?.text = Judge.Level(rawValue: row)!.fullDescription
        updateSaveButtonState()
        pickerView.becomeFirstResponder()
    }
    
    /// Persists a new or updated judge, then unwinds to the list.
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let level = Judge.Level.valueFor(description: (levelCell.detailTextLabel?.text)!)
              
        if name != nil && level != nil{
            let judgeInfo = JudgeInfo(name: name!, level: level!)
            
            if addingNewJudge{
                _ = JudgeListManager.GetInstance().addJudge(judgeInfo)
            }
            else{
                JudgeListManager.GetInstance().updateSelectedJudgeWith(judgeInfo)
            }
        }
        
        self.performSegue(withIdentifier: "unwindToJudgeInfoList", sender: self)
    }
    
    /// Cancels editing and unwinds without saving.
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "unwindToJudgeInfoList", sender: self)
    }
    
    /// Hides or shows the picker row based on `showPicker`.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 && !showPicker{
            return 0
        }
        else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    /// Toggles the picker when the level row is tapped.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        nameTextField.resignFirstResponder()
        nameTextField.endEditing(true)
        
        if indexPath.row == 1{
            showPicker = !showPicker
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    /// Validates the current name/level and toggles the save button.
    @IBAction func handleNameEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }
    
    /// Enables save when the name is non-empty and (for new judges) not a duplicate.
    func updateSaveButtonState(){
        // Make sure that the judge name is valid and is not a duplicate of an existing judge
        // Enable the add new judge button if:
        //  1. The Name is not empty and
        //  2. The judge does not already exist
        if let judgeNameText = nameTextField.text{
            if !judgeNameText.isEmpty{
                if let level = Judge.Level.init(rawValue: levelPicker.selectedRow(inComponent: 0)){
                    let info = JudgeInfo(name: judgeNameText, level:level)
                    saveButton.isEnabled = (addingNewJudge && JudgeListManager.GetInstance().indexOfJudge(info) == -1) || (!addingNewJudge && !judgeNameText.isEmpty)
                    return
                }
            }
        }
        saveButton.isEnabled = false
    }
}
