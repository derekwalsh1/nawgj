//
//  JudgeDetailViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeDetailViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate,UIPickerViewDelegate, UIPickerViewDataSource  {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var levelTextField: UITextField!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    //MARK: Properties
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var judge: Judge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        
        // Set up views if editing an existing Judge.
        if let judge = judge {
            navigationItem.title = judge.name
            nameTextField.text = judge.name
            levelTextField.text = judge.level.description
        }
        else{
            judge = Judge(name: "New Judge", level: Judge.Level.FourToEight, expenses:Array<Expense>())
        }
        let levelPickerView = UIPickerView()
        levelPickerView.delegate = self
        levelPickerView.dataSource = self
        
        levelTextField.inputView = levelPickerView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        navigationItem.title = textField.text
        textField.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    //MARK: UIPickerView
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Judge.Level.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Judge.Level(rawValue: row)?.description;
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        levelTextField.text = Judge.Level(rawValue: row)?.description
        levelTextField.resignFirstResponder()
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        let isPresentingInAddJudgeMode = presentingViewController is UINavigationController
        
        if isPresentingInAddJudgeMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The JudgeDetailViewController is not inside a navigation controller.")
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem, button === doneButton{
            judge?.name = nameTextField.text!
            judge?.level = Judge.Level.valueFor(description: levelTextField.text!)!
        }
    }

}
