//
//  JudgeDetailViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeDetailViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var levelCell: UITableViewCell!
    @IBOutlet weak var manageExpensesCell: UITableViewCell!
    @IBOutlet weak var manageFeesCell: UITableViewCell!
    @IBOutlet weak var judgeSummaryTable: UITableView!
    @IBOutlet weak var notesTextField: UITextField!
    @IBOutlet weak var paidSwitch: UISwitch!
    @IBOutlet weak var paidLabel: UILabel!
    @IBOutlet weak var meetRefLabel: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var judgeNameCell: UITableViewCell!
    @IBOutlet weak var meetRefSwitch: UISwitch!
    @IBOutlet weak var w9ReceivedSwitch: UISwitch!
    @IBOutlet weak var w9ReceivedLabel: UILabel!
    @IBOutlet weak var meetRefFeeCell: UITableViewCell!
    @IBOutlet weak var meetRefFeeLabel: UILabel!
    @IBOutlet weak var meetRefFeeAmountTextField: UITextField!
    
    //MARK: Properties
    var judge: Judge?
    var meet: Meet?
    var showJudgePicker : Bool = false
    var judgeSummaryDelegate : JudgeSummaryTableViewDelegate? = nil
    var numberFormatter : NumberFormatter = NumberFormatter()
    var numberFormatterDecimal : NumberFormatter = NumberFormatter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .currency
        numberFormatterDecimal.numberStyle = .decimal
        notesTextField.delegate = self
        
        judge = MeetListManager.GetInstance().getSelectedJudge()
        meet = MeetListManager.GetInstance().getSelectedMeet()
        
        judgeSummaryDelegate = JudgeSummaryTableViewDelegate(judge: judge!, meet: meet!)
        judgeSummaryTable.delegate = judgeSummaryDelegate
        judgeSummaryTable.dataSource = judgeSummaryDelegate
        
        navigationItem.title = judge!.name
        judgeNameCell.detailTextLabel?.text = judge!.name
        
        judgeNameCell.textLabel?.textColor = self.view.tintColor
        levelCell.textLabel?.textColor = self.view.tintColor
        notesLabel.textColor = self.view.tintColor
        paidLabel.textColor = self.view.tintColor
        meetRefLabel.textColor = self.view.tintColor
        w9ReceivedLabel.textColor = self.view.tintColor
        meetRefFeeLabel.textColor = self.view.tintColor
        
        levelCell.detailTextLabel?.text = judge!.level.fullDescription
        
        handleJudgeDetailsChanged()
    }
    
    func handleJudgeDetailsChanged(){
        if let judge = judge{
            navigationItem.title = judge.name
            judgeNameCell.detailTextLabel?.text = judge.name
            manageFeesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge.totalFees() as NSNumber)!)
            manageExpensesCell.detailTextLabel?.text = String(format: "Total: %@", numberFormatter.string(from: judge.totalExpenses() as NSNumber)!)
            notesTextField.text = judge.getNotes()
            meetRefFeeAmountTextField.text = numberFormatterDecimal.string(from: NSNumber(value: judge.getMeetRefereeFee()))
                
            paidSwitch.setOn(judge.isPaid(), animated: false)
            meetRefSwitch.setOn(judge.isMeetRef(), animated: false)
            w9ReceivedSwitch.setOn(judge.isW9Received(), animated: false)
            
            
            judgeSummaryTable.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Show/Hide Date Picker Code
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3{
            let numberOfFeeCells : CGFloat = CGFloat((judge?.fees.count)! + 1)
            let numberOfExpenseCells : CGFloat = CGFloat((judge?.expenses.count)! + 2)
            let rowHeight = judgeSummaryTable!.estimatedRowHeight
            let headerHeight = judgeSummaryTable!.estimatedSectionHeaderHeight
            let footerHeight = judgeSummaryTable!.estimatedSectionFooterHeight
            
            return (2 * headerHeight) + (2 * footerHeight) + CGFloat(((numberOfFeeCells + numberOfExpenseCells)) * rowHeight)
        }
        else if indexPath.section == 0 && indexPath.row == 5{
            if let judge = judge{
                return judge.isMeetRef() ? super.tableView(tableView, heightForRowAt: indexPath) : 0
            }
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
        else{
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        saveJudge()
    }

    func saveJudge(){
        if let judge = judge{
            judge.name = judgeNameCell.detailTextLabel!.text ?? "Unknown Judge"
            judge.setNotes(notesTextField.text ?? "")
            judge.setPaid(paidSwitch.isOn)
            judge.setMeetRef(meetRefSwitch.isOn)
            judge.changeLevel(level: Judge.Level.valueFor(description: levelCell.detailTextLabel!.text!)!)
            judge.setW9Received(w9ReceivedSwitch.isOn)
            
            MeetListManager.GetInstance().updateSelectedJudgeWith(judge: judge)
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToJudgeDetails(sender: UIStoryboardSegue){
        
        if let selectedJudgeInfo = JudgeListManager.GetInstance().selectedJudge{
            judgeNameCell.detailTextLabel!.text = selectedJudgeInfo.name
            levelCell.detailTextLabel!.text! = selectedJudgeInfo.level.fullDescription
        }
        
        saveJudge()
        
        if let delegate = judgeSummaryDelegate, let judge = judge{
            delegate.judge = judge
        }
        
        tableView.reloadData()
        judgeSummaryTable.reloadData()
        handleJudgeDetailsChanged()
    }
    
    @IBAction func unwindFromJudgeListWithSender(sender: UIStoryboardSegue){
        self.unwindToJudgeDetails(sender: sender)
    }
    
    @IBAction func meetRefSwitchChanged(_ sender: UISwitch) {
        if let judge = self.judge{
            judge.setMeetRef(meetRefSwitch.isOn)
            
        }
        handleJudgeDetailsChanged()
        tableView.reloadData()
        
        if meetRefSwitch.isOn{
            meetRefFeeAmountTextField.becomeFirstResponder()
        }
    }
    @IBAction func meetRefFeeEditingChanged(_ sender: UITextField) {
        if let amount = numberFormatterDecimal.number(from: meetRefFeeAmountTextField.text ?? "0"){
            judge?.setMeetRefereeFee(Float(truncating: amount))
        }
    }
    @IBAction func meetRefFeeValueChanged(_ sender: UITextField) {
        if let amount = numberFormatterDecimal.number(from: meetRefFeeAmountTextField.text ?? "0"){
            judge?.setMeetRefereeFee(Float(truncating: amount))
        }
    }
}
