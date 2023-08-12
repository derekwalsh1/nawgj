//
//  ExpenseDetailsViewContoroller.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class LodgingExpenseDetailsViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    //MARK: Properties
    var expense: Expense?
    var judge : Judge?
    
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    
    //MARK: Outlets
    @IBOutlet weak var lodgingTotalTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var expenseDatePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // Outlets for lodging UI components
    @IBOutlet weak var numberOfNightsStepper: UIStepper!
    @IBOutlet weak var numberOfNightsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the selected expense and judge from the meet list manager singleton
        expense = MeetListManager.GetInstance().getSelectedExpense()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        imageView.image = UIImage(named: "lodging-83.5.png")
        
        dateFormatter.dateStyle = .long
        navigationItem.title = expense?.type.description
        numberFormatter.numberStyle = .decimal
        
        // Update the fields in the view based on the expense details. If no expense is available then the fields
        // become unavailable and only the cancel button is enabled
        if let expense = expense{
            
            if let amountPerNight = expense.amountPerNight, let totalNights = expense.totalNights {
                let totalLodgingCost = amountPerNight * Float(totalNights)
                if let formattedTotalLodgingCost = numberFormatter.string(from: NSNumber(value: totalLodgingCost)) {
                    lodgingTotalTextField.text = formattedTotalLodgingCost
                }
            }
            
            notesTextView.text = expense.notes
            expenseDatePicker.date = (expense.date) ?? Date()
            
            lodgingTotalTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
            notesTextView.delegate = self
            lodgingTotalTextField.delegate = self
            
            numberOfNightsStepper.value = Double(expense.totalNights ?? 1)
            numberOfNightsLabel.text = numberFormatter.string(for: numberOfNightsStepper.value)
        }
        else{
            lodgingTotalTextField.isEnabled = false;
            notesTextView.isEditable = false
            expenseDatePicker.isEnabled = false
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UpdateUIComponents()
    }
   
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    @objc func myTextFieldDidChange(_ textField: UITextField) {
        UpdateUIComponents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        notesTextView.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.notesTextView.resignFirstResponder()
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let barButtonItem = sender as? UIBarButtonItem {
            if barButtonItem.title != "Cancel"{
                saveExpense()
            }
        }
    }
    
    @IBAction func totalNightsStepperValueChanged(_ sender: UIStepper) {
        numberOfNightsLabel.text = String(Int(sender.value))
        expense?.totalNights = Int(sender.value)
        UpdateUIComponents()
    }
    
    func UpdateUIComponents(){
        if let expense = expense{
            doneButton.isEnabled = false
            if let text = lodgingTotalTextField.text, !text.isEmpty, let number = numberFormatter.number(from: text), numberOfNightsStepper.value > 0{
                expense.amountPerNight = number.floatValue / Float(numberOfNightsStepper.value)
                doneButton.isEnabled = true
            }
        }
        else{
            doneButton.isEnabled = false
        }
    }
    
    func saveExpense(){
        if let expense = expense{
            expense.notes = notesTextView.text ?? " "
            expense.date = expenseDatePicker.date
            expense.totalNights = Int(numberOfNightsStepper.value)
            MeetListManager.GetInstance().updateSelectedExpenseWith(expense: expense)
        }
    }
}
