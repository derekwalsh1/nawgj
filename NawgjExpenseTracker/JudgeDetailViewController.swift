//
//  JudgeDetailViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeDetailViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var levelCell: UITableViewCell!
    @IBOutlet weak var manageExpensesCell: UITableViewCell!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var manageFeesCell: UITableViewCell!
    @IBOutlet weak var judgeSummaryTable: UITableView!
    
    //MARK: Properties
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var judge: Judge?
    var meet: Meet?
    var showLevelPicker : Bool = false
    var judgeSummaryDelegate : JudgeSummaryTableViewDelegate? = nil
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .currency
        nameTextField.delegate = self
        
        
        // Set up views if editing an existing Judge.
        if judge == nil{
            judge = Judge(name: "New Judge", level: Judge.Level.FourToEight, fees: Array<Fee>())
            
            // Add fees for each configured meet day if any days have been configured
            for day in (meet?.days)!{
                let fee = Fee(date: day.meetDate, hours: day.totalBillableTimeInHours(), rate: (judge?.level.rate)!, notes: "")
                judge?.fees.append(fee!)
            }
        }
        self.levelPicker.delegate = self
        self.levelPicker.dataSource = self
        
        judgeSummaryDelegate = JudgeSummaryTableViewDelegate(judge: judge!, meet: meet!)
        judgeSummaryTable.delegate = judgeSummaryDelegate
        judgeSummaryTable.dataSource = judgeSummaryDelegate
        
        navigationItem.title = judge!.name
        nameTextField.text = judge!.name
        levelCell.textLabel?.textColor = self.view.tintColor
        levelCell.detailTextLabel?.text = judge!.level.description
        levelPicker.selectRow(judge!.level.rawValue, inComponent: 0, animated: false)
        
        handleJudgeDetailsChanged()
    }
    
    func handleJudgeDetailsChanged(){
        manageFeesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge!.totalFees() as NSNumber)!)
        manageExpensesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge!.totalExpenses() as NSNumber)!)
        judgeSummaryTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Show/Hide Date Picker Code
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        
        switch(section){
        case 0:
            switch(row){
            case 1:
                showLevelPicker = !showLevelPicker
                tableView.beginUpdates()
                tableView.endUpdates()
                
            default:
                break
            }
            
        case 1:
            break
            
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !showLevelPicker && indexPath.row == 2 && indexPath.section == 0{
            return 0
        }
        else {
            if indexPath.section == 3{
                let numberOfFeeCells : CGFloat = CGFloat((judge?.fees.count)! + 1)
                let numberOfExpenseCells : CGFloat = CGFloat((judge?.expenses.count)! + 1)
                let rowHeight = judgeSummaryTable!.estimatedRowHeight
                let headerHeight = judgeSummaryTable!.estimatedSectionHeaderHeight
                let footerHeight = judgeSummaryTable!.estimatedSectionFooterHeight
                
                return (2 * headerHeight) + (2 * footerHeight) + CGFloat(((numberOfFeeCells + numberOfExpenseCells)) * rowHeight)
            }
            else{
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        }
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
        levelCell.detailTextLabel?.text = Judge.Level(rawValue: row)?.description
        judge?.changeLevel(level: Judge.Level(rawValue: row)!)
        handleJudgeDetailsChanged()
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
            judge?.changeLevel(level:  Judge.Level.valueFor(description: (levelCell.detailTextLabel?.text!)!)!)
        }
        
        switch segue.identifier {
        case "ShowFeeTable":
            guard let feeTableViewController = segue.destination as? FeeTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            feeTableViewController.judge = judge
            feeTableViewController.meet = meet
            break
        case "ShowExpenseTable":
            guard let expenseTableViewController = segue.destination as? ExpensesTableViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            expenseTableViewController.judge = judge
            expenseTableViewController.meet = meet
            break
        default:
            break
        }
    }

    //MARK: Actions
    @IBAction func unwindToJudgeDetailsFromFeeList(sender: UIStoryboardSegue) {
        manageFeesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge!.totalFees() as NSNumber)!)
        judgeSummaryDelegate?.judge = judge!
        handleJudgeDetailsChanged()
    }
    
    @IBAction func unwindToJudgeDetailsFromExpenseList(sender: UIStoryboardSegue) {
        manageExpensesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge!.totalExpenses() as NSNumber)!)
        judgeSummaryDelegate?.judge = judge!
        handleJudgeDetailsChanged()
    }
}
