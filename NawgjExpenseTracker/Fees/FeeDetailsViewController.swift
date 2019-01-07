//
//  FeeDetailsViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

class FeeDetailsViewController: UITableViewController {
    
    //MARK: Properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var totalHoursCell: UITableViewCell!
    @IBOutlet weak var breakTimeCell: UITableViewCell!
    @IBOutlet weak var billableHoursCell: UITableViewCell!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var totalFeeCell: UITableViewCell!
    @IBOutlet weak var stepperValueLabel: UILabel!
    @IBOutlet weak var judgeHoursStepper: UIStepper!
    @IBOutlet weak var overrideHoursSwitch: UISwitch!
    @IBOutlet weak var judgeNotWorkingSwitch: UISwitch!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var fee: Fee?
    var judge: Judge?
    var meetDay: MeetDay?
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .full
        numberFormatter.numberStyle = .currency
        let tintColor = self.view.tintColor
        
        // Initialize the title and use the blue tint color for the title labels
        navigationItem.title = dateFormatter.string(from: (fee?.date)!)
        for item in [dateCell, totalHoursCell, breakTimeCell, billableHoursCell, rateCell, totalFeeCell]{
                item?.textLabel?.textColor = tintColor
        }
        
        // Now fill in the detail for each cell
        dateCell.detailTextLabel?.text = dateFormatter.string(from: (fee?.date)!)
        totalHoursCell.detailTextLabel?.text = String(format: "%0.2f Hours", (meetDay?.totalTimeInHours())!)
        breakTimeCell.detailTextLabel?.text = String(format: "%0.2f Hours", (meetDay?.breakTimeInHours())!)
        judgeHoursStepper.value = Double(fee!.hours)
        
        overrideHoursSwitch.setOn(fee!.hoursOverridden, animated: false)
        overrideHoursSwitch.isEnabled = !(fee!.exclude ?? false)
        judgeNotWorkingSwitch.setOn(fee!.exclude ?? false, animated: false)
        updateAdjustableLabels()
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
        if indexPath.section == 1 && indexPath.row == 1 {
            return overrideHoursSwitch.isOn ? 80 : 0
        }
        else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func hoursStepperValueChanged(_ sender: UIStepper) {
        updateAdjustableLabels()
    }
    
    //MARK: Navigation
    @IBAction func done(_ sender: UIBarButtonItem) {
        
        if (fee!.hoursOverridden != overrideHoursSwitch.isOn){
            let alert = UIAlertController(title: "Discard Changes to Fees?", message: nil, preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in }
            let actionDiscard = UIAlertAction(title: "Discard Changes", style: .default) { (action:UIAlertAction) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(actionCancel)
            alert.addAction(actionDiscard)
            self.present(alert, animated: true)
        }
        else{
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem{
            if button === saveButton {
                saveUpdatedFees()
            }
        }
    }
    
    func saveUpdatedFees()
    {
        fee?.hoursOverridden = overrideHoursSwitch.isOn
        fee?.exclude = judgeNotWorkingSwitch.isOn
        fee?.hours = (fee?.hoursOverridden)! ? Float(judgeHoursStepper.value) : (meetDay?.totalBillableTimeInHours())!
    }
    
    @IBAction func overrideHoursSwitchChanged(_ sender: UISwitch) {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        updateAdjustableLabels()
    }
    
    @IBAction func udgeNotWorkingSwitchChanged(_ sender: UISwitch) {
        updateAdjustableLabels()
    }
    
    @IBAction func overrideRateSwitchChanged(_ sender: UISwitch) {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        updateAdjustableLabels()
    }
    
    func updateAdjustableLabels(){
        let adjustedHours = Float(judgeHoursStepper.value)
        let billableHours = overrideHoursSwitch.isOn ? adjustedHours : meetDay?.totalBillableTimeInHours()
        
        stepperValueLabel.text = String(format: "%0.2f Hours", adjustedHours)
        billableHoursCell.detailTextLabel?.text = String(format: "%0.2f Hours", billableHours!)
        let rate = judge?.level.rate
        rateCell.detailTextLabel?.text = String(format: "$%0.1f/Hour ", (judge?.level.rate)!) + "(\(judge?.level.description ?? "Unknown"))"
        
        let totalFee = judgeNotWorkingSwitch.isOn ? 0.0 : billableHours! * rate!
        totalFeeCell.detailTextLabel?.text = numberFormatter.string(from: totalFee as NSNumber)
        
        overrideHoursSwitch.isEnabled = !judgeNotWorkingSwitch.isOn
    }
}
