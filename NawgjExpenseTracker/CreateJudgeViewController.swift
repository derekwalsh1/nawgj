//
//  CreateJudgeViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek Walsh on 11/5/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

class CreateJudgeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var judgeLevelPicker: UIPickerView!
    @IBOutlet weak var judgeNameTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        judgeLevelPicker.dataSource = self
        judgeLevelPicker.delegate = self
        
        updateDoneButtonState()
        let defaultIndex = Judge.Level.selectableCases.count > 1 ? Judge.Level.selectableCases.count - 2 : 0
        judgeLevelPicker.selectRow(defaultIndex, inComponent: 0, animated: false)
        
        judgeNameTextField.becomeFirstResponder()
    }
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    @IBAction func cancelButtonSelected(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "unwindToSelectJudges", sender: self)
    }
    
    @IBAction func doneButtonSelected(_ sender: UIBarButtonItem) {
        
        if let judgeNameText = judgeNameTextField.text{
            if !judgeNameText.isEmpty{
                let level = Judge.Level.selectableCases[judgeLevelPicker.selectedRow(inComponent: 0)]
                _ = JudgeListManager.GetInstance().addJudge(JudgeInfo(name: judgeNameText, level:level))
            }
        }
        
        self.performSegue(withIdentifier: "unwindToSelectJudges", sender: self)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Judge.Level.selectableCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Judge.Level.selectableCases[row].description
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateDoneButtonState()
    }
    
    func updateDoneButtonState(){
        // Enabled the add new judge button if:
        //  1. The Name is not empty and
        //  2. The judge does not already exist
        if let judgeNameText = judgeNameTextField.text{
            if !judgeNameText.isEmpty{
                let level = Judge.Level.selectableCases[judgeLevelPicker.selectedRow(inComponent: 0)]
                let info = JudgeInfo(name: judgeNameText, level:level)
                doneButton.isEnabled = JudgeListManager.GetInstance().indexOfJudge(info) == -1
                return
            }
        }
        doneButton.isEnabled = false
    }
    
    @IBAction func judgeNameTextFieldEditingChanged(_ sender: UITextField) {
        updateDoneButtonState()
    }
}
