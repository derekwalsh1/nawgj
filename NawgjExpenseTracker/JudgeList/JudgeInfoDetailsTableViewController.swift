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
    
    var judgeInfo : JudgeInfo?
    var showPicker : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        judgeInfo = JudgeListManager.GetInstance().selectedJudge
        nameTextField.delegate = self
        levelPicker.dataSource = self
        levelPicker.delegate = self
        
        if let judgeInfo = judgeInfo{
            nameTextField.text = judgeInfo.name
            levelCell.detailTextLabel!.text = judgeInfo.level.fullDescription
            //levelPicker.selectedRow(inComponent: judgeInfo.level.rawValue)
        }
        
        nameLabel?.textColor = self.view.tintColor
        levelCell.textLabel?.textColor = self.view.tintColor
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
        judgeInfo?.level = Judge.Level(rawValue: row)!
        levelCell.detailTextLabel?.text = judgeInfo?.level.fullDescription
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        saveJudgeInfo()
    }
    
    func saveJudgeInfo(){
        if let judgeInfo = judgeInfo{
            judgeInfo.name = nameTextField.text ?? "New Judge"
            judgeInfo.level = Judge.Level.valueFor(description: (levelCell.detailTextLabel?.text)!)!
            
            // If a judge with this name already exists don't update the judge info
            if JudgeListManager.GetInstance().indexOfJudge(judgeInfo) < 0{
                JudgeListManager.GetInstance().updateSelectedJudgeWith(judgeInfo)
            }
        }
        
        cleanupJudgeList()
    }
    
    func cleanupJudgeList(){
        let judgeInfo = JudgeInfo(name: "New Judge", level: Judge.Level.National)
        let judgeIndex = JudgeListManager.GetInstance().indexOfJudge(judgeInfo)
        
        if judgeIndex >= 0{
            JudgeListManager.GetInstance().removeJudgeAt(judgeIndex)
        }
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
        
        if indexPath.row == 1{
            showPicker = !showPicker
            
            if showPicker{
                levelPicker.selectRow((judgeInfo?.level.rawValue)!, inComponent: 0, animated: false)
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
