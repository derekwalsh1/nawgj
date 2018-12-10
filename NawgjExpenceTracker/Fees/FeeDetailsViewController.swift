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
    @IBOutlet weak var overrideRateSwitch: UISwitch!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var fee: Fee?
    var judge: Judge?
    var meetDay: MeetDay?
    var dateFormatter : DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateStyle = .medium
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
        billableHoursCell.detailTextLabel?.text = String(format: "%0.2f Hours", (meetDay?.totalBillableTimeInHours())!)
        rateCell.detailTextLabel?.text = String(format: "%0.1f/Hour ", (judge?.level.rate)!) + "(\(judge?.level.description ?? "Unknown"))"
        totalFeeCell.detailTextLabel?.text = String(format: "$%0.2f", (fee?.getFeeTotal())!)
        
        stepperValueLabel.text = String(format: "%0.2f Hours", fee!.hours)
        judgeHoursStepper.value = Double(fee!.hours)
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func hoursStepperValueChanged(_ sender: UIStepper) {
        stepperValueLabel.text = String(format: "%0.2f Hours", sender.value)
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem{
            if button === saveButton {
                // TODO : Update the fee object
            }
            else
            {
                return
            }
        }
    }
}


