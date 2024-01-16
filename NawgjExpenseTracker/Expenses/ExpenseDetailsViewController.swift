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
    var isLodgingExpense : Bool = false
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    var showDatePicker : Bool = false
    var showManualMileageRate : Bool = false
    
    //MARK: Outlets
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var expenseDateCell: UITableViewCell!
    @IBOutlet weak var expenseDatePicker: UIDatePicker!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    // Outlets for mileage related components
    @IBOutlet weak var manualMileageRateSetCell: UITableViewCell!
    @IBOutlet weak var enableManualMileageRateEditSwitch: UISwitch!
    @IBOutlet weak var mileageRateValueCell: UITableViewCell!
    @IBOutlet weak var mileageRateTextField: UITextField!
    
    // Outlets for lodging UI components
    @IBOutlet weak var numberOfNightsStepper: UIStepper!
    @IBOutlet weak var privateRoomRequestedSwitch: UISwitch!
    @IBOutlet weak var nightlyRateTextField: UITextField!
    @IBOutlet weak var numberOfNightsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the selected expense and judge from the meet list manager singleton
        expense = MeetListManager.GetInstance().getSelectedExpense()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        
        // Based on the expense type, load the appropriate image related to the expense
        loadExpenseImage()
        
        dateFormatter.dateStyle = .long
        navigationItem.title = expense?.type.description
        numberFormatter.numberStyle = .decimal
        
        // Update the fields in the view based on the expense details. If no expense is available then the fields
        // become unavailable and only the cancel button is enabled
        if let expense = expense{
            amountTextField.text = numberFormatter.string(from: NSNumber(value: expense.amount as Float))
            notesTextView.text = expense.notes
            expenseDateCell.detailTextLabel?.text = dateFormatter.string(from: (expense.date) ?? Date())
            expenseDatePicker.date = (expense.date) ?? Date()
            amountTextField.addTarget(self, action: #selector(myTextFieldDidChange), for: .editingChanged)
            notesTextView.delegate = self
            amountTextField.delegate = self
            
            // Enable the mileage rate cell if this is a mileage rate expense and populate the cell with the appropriate initial value
            isMileageExpense = expense.type == .Mileage
            
            // Enable the lodging related cells if this is a lodging expense
            isLodgingExpense = expense.type == .Lodging
            
            titleLabel.text = isMileageExpense ? "Miles" : "Amount($)"
            
            mileageRateValueCell.isHidden =  !isMileageExpense
            manualMileageRateSetCell.isHidden = !isMileageExpense
            enableManualMileageRateEditSwitch.isEnabled = isMileageExpense
            mileageRateTextField.isEnabled = isMileageExpense
        
            if expense.amount == 0{
                amountTextField.becomeFirstResponder()
            }
            
            if isMileageExpense{
                if let isCustomMileage = expense.isCustomMileageRate{
                    enableManualMileageRateEditSwitch.isOn = isCustomMileage
                }
                else{
                    expense.isCustomMileageRate = false
                    enableManualMileageRateEditSwitch.isOn = false
                }
                
                if expense.mileageRate == 0{
                    expense.mileageRate = Meet.getMileageRate(forDate: expenseDatePicker.date)
                }
                
                mileageRateTextField.text = numberFormatter.string(from: NSNumber(value: expense.mileageRate as Float))
                mileageRateTextField.isEnabled = enableManualMileageRateEditSwitch.isOn
            }
            
            if isLodgingExpense{
                privateRoomRequestedSwitch.isOn = expense.isPrivateLodgingRequested ?? false
                nightlyRateTextField.text = numberFormatter.string(from: NSNumber(value: Float(expense.amountPerNight ?? 0.0)))
                numberOfNightsLabel.text = numberFormatter.string(from: NSNumber(value: Int(expense.totalNights ?? 0)))
                numberOfNightsStepper.value = Double(expense.totalNights ?? 0)
                amountTextField.text = String(Float(expense.getExpenseTotal()))
                amountTextField.isEnabled = false
                nightlyRateTextField.isEnabled = !privateRoomRequestedSwitch.isOn
            }
        }
        else{
            amountTextField.isEnabled = false
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
        checkAndEnableDoneButton()
    }
   
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    
    func loadExpenseImage(){
        if let type = expense?.type{
            switch type{
            case .Meals:
                imageView.image = UIImage(named: "meals-83.5.png")
            case .Transportation:
                imageView.image = UIImage(named: "transportation-83.5.png")
            case .Toll:
                imageView.image = UIImage(named: "bridge-83.5.png")
            case .Mileage:
                imageView.image = UIImage(named: "gas-83.5.png")
            case .Parking:
                imageView.image = UIImage(named: "parking-83.5.png")
            case .Airfare:
                imageView.image = UIImage(named: "airport-83.5.png")
            case .Lodging:
                imageView.image = UIImage(named: "lodging-83.5.png")
            case .Other:
                imageView.image = UIImage(named: "splat-83.5.png")
            }
        }
    }
    
    @objc func myTextFieldDidChange(_ textField: UITextField) {
        checkAndEnableDoneButton()
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
        
        // If the date entry field is in use, the showDatePicker variable will be true
        // and the height of the row should be determined by the table view. Otherwise
        // it is hidden by setting the row height to 0.
        if indexPath.section == 1 {
            if (indexPath.row == 1 || indexPath.row == 2) && !isMileageExpense {
                return 0;
            }
            else if (indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5) && !isLodgingExpense {
                return 0
            }
            else if indexPath.row == 7 && !showDatePicker {
                return 0
            }
        }
        
        // The expense details table rows are configured as follows:
        //
        // Row 0 = Amount (or Miles for mileage) Cell
        // Row 1 = Manual Set Mileage Rate Cell (Hidden if expense type is not mileage)
        // Row 2 = Mileage Rate Cell (Hidden if not mileage expense)
        // Row 3 = Lodging => Number of nights
        // Row 4 = Lodging => Nightly rate
        // Row 5 = Lodging => Single Room Requested
        // Row 6 = Date Value Cell
        // Row 7 = Date Picker
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // If the user clicks on the date field, then expand or collapse the field and
        // refresh the table to update the view
        if indexPath.section == 1 && indexPath.row == 6 {
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

        if let barButtonItem = sender as? UIBarButtonItem {
            if barButtonItem.title != "Cancel"{
                saveExpense()
            }
        }
    }
    
    @IBAction func onManualRateChanged(_ sender: UISwitch) {
        mileageRateTextField.isEnabled = sender.isOn;
        
        // If the mileage rate changed to auto, then update the mileage rate text field to the auto rate
        if !sender.isOn{
            mileageRateTextField.text = numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: expenseDatePicker.date ) as Float))
        }
    }
    
    
    
    @IBAction func expenseDateChanged(_ sender: UIDatePicker) {
        expenseDateCell.detailTextLabel?.text = dateFormatter.string(from: sender.date)
        
        // Whenever the expense date is changed the mileage rate for that date needs to be determined
        // if the selected expense is a mileage expense and a custom/manual mileage rate has not been
        // selected.
        if isMileageExpense{
            if !enableManualMileageRateEditSwitch.isOn{
                mileageRateTextField.text = numberFormatter.string(from: NSNumber(value: Meet.getMileageRate(forDate: expenseDatePicker.date ) as Float))
            }
        }
    }
    
    @IBAction func privateRoomSwitchChanged(_ sender: UISwitch) {
        nightlyRateTextField.isEnabled = !sender.isOn
        
        if(sender.isOn)
        {
            expense?.amountPerNight = Float(Meet.SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS)
            nightlyRateTextField.text = String(Float(expense?.amountPerNight ?? 0.0))
        }
        
        amountTextField.text = String(Float(expense?.getExpenseTotal() ?? 0.0))
    }
    
    @IBAction func totalNightsStepperValueChanged(_ sender: UIStepper) {
        numberOfNightsLabel.text = String(Int(sender.value))
        expense?.totalNights = Int(sender.value)
        amountTextField.text = String(Float(expense?.getExpenseTotal() ?? 0.0))
    }
    
    @IBAction func amountPerNightEdited(_ sender: UITextField) {
        expense?.amountPerNight = Float(sender.text ?? "0.0")
        amountTextField.text = String(Float(expense?.getExpenseTotal() ?? 0.0))
    }
    
    func checkAndEnableDoneButton(){
        // The amount field needs to be a valid decimal value.
        if let text = amountTextField.text, !text.isEmpty{
            let number = numberFormatter.number(from: text)
            let enable = number != nil
            doneButton.isEnabled = enable
        }
        else{
            doneButton.isEnabled = false
        }
    }
    
    func saveExpense(){
        if let text = amountTextField.text, let expense = expense{
            if let amount = numberFormatter.number(from: text){
                expense.amount = amount.floatValue
            }
            else{
                expense.amount = 0.0
            }
            expense.notes = notesTextView.text ?? " "
            expense.date = expenseDatePicker.date
            
            if isMileageExpense{
                expense.isCustomMileageRate = enableManualMileageRateEditSwitch.isOn
                if let mileageText = mileageRateTextField.text{
                    if let amount = numberFormatter.number(from: mileageText){
                        expense.mileageRate = amount.floatValue
                    }
                }
            }
            
            if isLodgingExpense{
                expense.isPrivateLodgingRequested = privateRoomRequestedSwitch.isOn
                if expense.isPrivateLodgingRequested ?? false {
                    expense.amountPerNight = Meet.SINGLE_ROOM_REQUEST_MAX_DAILY_EXPENSE_DOLLARS
                }
                else{
                    expense.amountPerNight = numberFormatter.number(from: nightlyRateTextField.text ?? "0.0") as? Float
                }
                expense.totalNights = Int(numberOfNightsStepper.value)
            }
            
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
        do{
            let regex = try NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
            amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
            
            let double = (amountWithPrefix as NSString).doubleValue
            number = NSNumber(value: (double / 100))
            
            // if first number is 0 or all numbers were deleted
            guard number != 0 as NSNumber else {
                return ""
            }
        }
        catch{
            os_log("Failed to format currency string ", log: OSLog.default, type: .error)
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
        do{
            let regex = try NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
            amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
            
            let double = (amountWithPrefix as NSString).doubleValue
            number = NSNumber(value: (double / 100))
            
            // if first number is 0 or all numbers were deleted
            guard number != 0 as NSNumber else {
                return ""
            }
        }
        catch{
            os_log("Failed to format currency string ", log: OSLog.default, type: .error)
            return ""
        }
        
        return formatter.string(from: number)!
    }
}
