//
//  JudgeDetailViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeDetailViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate  {
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    
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
            nameTextField.text   = judge.name
        }
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
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
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
     }
}
