//
//  JudgeInfoDetailsTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/23/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

class JudgeInfoDetailsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var levelCell: UITableViewCell!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var showPicker : Bool = false
    var addingNewJudge : Bool = false
    
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
    
    @IBAction func nameEditingEnded(_ sender: UITextField) {
        updateNameField()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateSaveButtonState()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateNameField()
    }
    
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
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Judge.Level.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let level = Judge.Level(rawValue: row)!
        return level.description;
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        levelCell.detailTextLabel?.text = Judge.Level(rawValue: row)!.fullDescription
        updateSaveButtonState()
        pickerView.becomeFirstResponder()
    }
    
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
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "unwindToJudgeInfoList", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 2 && !showPicker{
            return 0
        }
        else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
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
    
    @IBAction func handleNameEditingChanged(_ sender: UITextField) {
        updateSaveButtonState()
    }
    
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
