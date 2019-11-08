//
//  FeeDetailsViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

class FeeDetailsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    //MARK: Properties
    @IBOutlet weak var dateCell: UITableViewCell!
    @IBOutlet weak var totalHoursCell: UITableViewCell!
    @IBOutlet weak var breakTimeCell: UITableViewCell!
    @IBOutlet weak var billableHoursCell: UITableViewCell!
    @IBOutlet weak var rateCell: UITableViewCell!
    @IBOutlet weak var totalFeeCell: UITableViewCell!
    @IBOutlet weak var overrideHoursSwitch: UISwitch!
    @IBOutlet weak var judgeNotWorkingSwitch: UISwitch!
    @IBOutlet weak var timePicker: UIPickerView!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var fee: Fee?
    var judge: Judge?
    var meetDay: MeetDay?
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    let formatter = DateComponentsFormatter()
    
    var pickerHoursData: [Int] = [Int]()
    var pickerMinutesData: [Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .full
        numberFormatter.numberStyle = .currency
        let tintColor = self.view.tintColor
        
        SetupTimePickerUI()
        
        fee = MeetListManager.GetInstance().getSelectedFee()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        
        // Initialize the title and use the blue tint color for the title labels
        navigationItem.title = dateFormatter.string(from: (fee?.date)!)
        for item in [dateCell, totalHoursCell, breakTimeCell, billableHoursCell, rateCell, totalFeeCell]{
                item?.textLabel?.textColor = tintColor
        }
        
        // There should be a meet day that corresponds to the date of the fee. We load that here so that we can present
        // details about the meet day that this fee is associated with
        MeetListManager.GetInstance().selectMeetDayForFee(fee : fee!)
        meetDay = MeetListManager.GetInstance().getSelectedMeetDay()
        
        // Now fill in the detail for each cell
        dateCell.detailTextLabel?.text = dateFormatter.string(from: (fee?.date)!)
        totalHoursCell.detailTextLabel?.text = formatter.string(from: TimeInterval((meetDay?.totalTimeInHours())!*60*60))!
        breakTimeCell.detailTextLabel?.text = formatter.string(from: TimeInterval((meetDay?.breakTimeInHours())!*60*60))!
        
        overrideHoursSwitch.setOn(fee!.hoursOverridden, animated: false)
        overrideHoursSwitch.isEnabled = !(fee!.exclude ?? false)
        judgeNotWorkingSwitch.setOn(fee!.exclude ?? false, animated: false)
        
        updateAdjustableLabels()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? pickerHoursData.count : pickerMinutesData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return component == 0 ? String(pickerHoursData[row]) + (row == 1 ? " hour" : " hours") : String(pickerMinutesData[row]) + (row == 1 ? " minute" : " minutes")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateAdjustableLabels()
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
            return overrideHoursSwitch.isOn ? timePicker.frame.size.height : 0
        }
        else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        saveUpdatedFees()
    }
    
    func saveUpdatedFees()
    {
        fee?.hoursOverridden = overrideHoursSwitch.isOn
        fee?.exclude = judgeNotWorkingSwitch.isOn
        fee?.hours = getBillableHours()
        
        MeetListManager.GetInstance().updateSelectedFeeWith(fee: fee!)
    }
    
    @IBAction func overrideHoursSwitchChanged(_ sender: UISwitch) {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        updateAdjustableLabels()
    }
    
    @IBAction func judgeNotWorkingSwitchChanged(_ sender: UISwitch) {
        tableView.beginUpdates()
        tableView.endUpdates()
        
        updateAdjustableLabels()
    }
    
    func getBillableHours() -> Float{
        let adjustedHours = Float(timePicker.selectedRow(inComponent: 0))
        let adjustedMinutes = Float(timePicker.selectedRow(inComponent: 1))
        let adjustedTotalTimeInHours = adjustedHours + (adjustedMinutes / 60.0)
            
        return overrideHoursSwitch.isOn ? adjustedTotalTimeInHours : (meetDay?.totalBillableTimeInHours())!
    }
    
    fileprivate func updateAdjustableLabels(){
        let billableHours = getBillableHours()

        billableHoursCell.detailTextLabel?.text = formatter.string(from: TimeInterval(billableHours*60*60))!
        
        let rate = judge?.level.rate
        rateCell.detailTextLabel?.text = String(format: "$%0.1f/Hour ", (judge?.level.rate)!) + "(\(judge?.level.description ?? "Unknown"))"
        
        let totalFee = judgeNotWorkingSwitch.isOn ? 0.0 : billableHours * rate!
        totalFeeCell.detailTextLabel?.text = numberFormatter.string(from: totalFee as NSNumber)
        
        overrideHoursSwitch.isEnabled = !judgeNotWorkingSwitch.isOn
    }
    
    fileprivate func SetupTimePickerUI() {
        // Create a list of options for hours worked
        for value in 0...24 {
            pickerHoursData.append(value)
        }
        
        // Creates a list of options for minutes over the hours worked
        for value in 0...60{
            pickerMinutesData.append(value)
        }
        
        self.timePicker.delegate = self
        self.timePicker.dataSource = self
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
    }
}
