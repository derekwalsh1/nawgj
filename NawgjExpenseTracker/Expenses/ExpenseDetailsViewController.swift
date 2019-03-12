//
//  ExpenseDetailsViewContoroller.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class ExpenseDetailsViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate {
    
    //MARK: Properties
    var expense: Expense?
    var judge : Judge?
    
    var isMileageExpense : Bool = false
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    
    var showDatePicker : Bool = false
    
    //MARK: Outlets
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var expenseDateCell: UITableViewCell!
    @IBOutlet weak var expenseDatePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        expense = MeetListManager.GetInstance().getSelectedExpense()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        
        loadExpenseImage()
        
        numberFormatter.numberStyle = .currency
        dateFormatter.dateStyle = .long
        
        navigationItem.title = expense?.type.description
        isMileageExpense = expense?.type == .Mileage
        amountTextField.text = isMileageExpense ? String(format: "%.2f", (expense?.amount)!) : numberFormatter.string(from: expense!.amount as NSNumber)!
        notesTextView.text = expense?.notes ?? " "
        
        titleLabel.text = isMileageExpense ? "Miles" : "Amount"
        amountTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
        
        expenseDateCell.detailTextLabel?.text = dateFormatter.string(from: (expense?.date) ?? Date())
        expenseDatePicker.date = (expense?.date) ?? Date()
        
        notesTextView.delegate = self
        amountTextField.delegate = self
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func loadExpenseImage(){
        if let type = expense?.type{
            switch type{
            case .Meals:
                imageView.image = UIImage(named: "meals")
            case .Transportation:
                imageView.image = UIImage(named: "transportation")
            case .Toll:
                imageView.image = UIImage(named: "tolls")
            case .Mileage:
                imageView.image = UIImage(named: "mileage")
            case .Parking:
                imageView.image = UIImage(named: "parking")
            case .Airfare:
                imageView.image = UIImage(named: "airfare")
            case .Other:
                imageView.image = UIImage(named: "other")
            }
            
        }
    }
    
    @objc func myTextFieldDidChange(_ textField: UITextField) {
        if let amountString = isMileageExpense ? textField.text?.milesInputFormatting() : textField.text?.currencyInputFormatting() {
            textField.text = amountString
        }
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
        if indexPath.section == 1 && indexPath.row == 2 && !showDatePicker {
            return 0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            showDatePicker = !showDatePicker
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        notesTextView.resignFirstResponder()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.notesTextView.resignFirstResponder()
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        saveExpense()
    }
    
    @IBAction func expenseDateChanged(_ sender: UIDatePicker) {
        expenseDateCell.detailTextLabel?.text = dateFormatter.string(from: sender.date)
    }
    
    func saveExpense(){
        if let text = amountTextField.text, let expense = expense{
            expense.amount = Float(isMileageExpense ? text : text.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))!
            expense.notes = notesTextView.text ?? " "
            expense.date = expenseDatePicker.date
            MeetListManager.GetInstance().updateSelectedExpenseWith(expense: expense)
        }
    }
}

extension String {
    
    // formatting text for currency textField
    func currencyInputFormatting() -> String {
        
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        var amountWithPrefix = self
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: (double / 100))
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
    
    func milesInputFormatting() -> String {
        
        var number: NSNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        var amountWithPrefix = self
        
        // remove from String: "$", ".", ","
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSNumber(value: (double / 100))
        
        // if first number is 0 or all numbers were deleted
        guard number != 0 as NSNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
}
