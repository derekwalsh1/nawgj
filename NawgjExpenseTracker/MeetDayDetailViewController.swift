//
//  MeetDayDetailViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/17/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class MeetDayDetailViewController: UITableViewController, UINavigationControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var meetDayDateCell: UITableViewCell!
    @IBOutlet weak var meetDayDatePicker: UIDatePicker!
    @IBOutlet weak var meetDayStartTimeCell: UITableViewCell!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var meetDayEndTimeCell: UITableViewCell!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var breaksSegmentedControl: UISegmentedControl!
    @IBOutlet weak var numberOfBreaksLabel: UILabel!
    
    @IBOutlet weak var totalTimeCell: UITableViewCell!
    @IBOutlet weak var billableTimeCell: UITableViewCell!
    @IBOutlet weak var breakTimeCell: UITableViewCell!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var showMeetDayDatePicker : Bool = false
    var showMeetDayStartTimePicker : Bool = false
    var showMeetDayEndTimePicker : Bool = false
    
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var meetDay: MeetDay?
    var dateFormatter : DateFormatter = DateFormatter()
    var timeFormatter : DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        timeFormatter.dateFormat = "h:mm a"
        
        meetDayDateCell.textLabel?.textColor = self.view.tintColor
        meetDayStartTimeCell.textLabel?.textColor = self.view.tintColor
        meetDayEndTimeCell.textLabel?.textColor = self.view.tintColor
        numberOfBreaksLabel.textColor = self.view.tintColor
        
        totalTimeCell.textLabel?.textColor = self.view.tintColor
        billableTimeCell.textLabel?.textColor = self.view.tintColor
        breakTimeCell.textLabel?.textColor = self.view.tintColor
        
        // Set up views if editing an existing Meet day.
        if let meetDay = meetDay {
            
            // Round each date down to the nearest quarter hour
            let calendar = Calendar.current
            var hour = calendar.component(.hour, from: meetDay.meetDate)
            var minute = calendar.component(.minute, from: meetDay.meetDate)
            var floorMinute = minute - (minute % 15)
            meetDayDatePicker.date = calendar.date(bySettingHour: hour,
                                          minute: floorMinute,
                                          second: 0, 
                                          of: meetDay.meetDate)!
            
            hour = calendar.component(.hour, from: meetDay.startTime)
            minute = calendar.component(.minute, from: meetDay.startTime)
            floorMinute = minute - (minute % 15)
            startTimePicker.date = calendar.date(bySettingHour: hour,
                                                 minute: floorMinute,
                                                 second: 0,
                                                 of: meetDay.startTime)!
            
            hour = calendar.component(.hour, from: meetDay.endTime)
            minute = calendar.component(.minute, from: meetDay.endTime)
            floorMinute = minute - (minute % 15)
            endTimePicker.date = calendar.date(bySettingHour: hour,
                                               minute: floorMinute,
                                               second: 0,
                                               of: meetDay.endTime)!
            
            breaksSegmentedControl.selectedSegmentIndex = meetDay.breaks
            updateUILabels()
        }
        else{
            let meetDate = Date()
            meetDayDatePicker.setDate(meetDate, animated: false)

            let startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: meetDate)
            startTimePicker.setDate(startTime!, animated: false)
            
            let endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: meetDate)
            endTimePicker.setDate(endTime!, animated: false)
            
            let numberOfBreaks = 2
            breaksSegmentedControl.selectedSegmentIndex = numberOfBreaks
            
            navigationItem.title = dateFormatter.string(from: meetDate)
            meetDay = MeetDay(meetDate: meetDate, startTime: startTime!, endTime: endTime!, breaks: numberOfBreaks)
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        let isPresentingInAddMeetDayMode = presentingViewController is UINavigationController
        
        if isPresentingInAddMeetDayMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController{
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The MeetDayDetailViewController is not inside a navigation controller.")
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem, button === doneButton{
            meetDay?.meetDate = meetDayDatePicker.date
            meetDay?.startTime = startTimePicker.date
            meetDay?.endTime = endTimePicker.date
            meetDay?.breaks = breaksSegmentedControl.selectedSegmentIndex
        }
    }
    
    func updateUILabels()
    {
        totalTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", MeetDay.totalTimeInHours(startTime: startTimePicker.date, endTime: endTimePicker.date)) as String
        billableTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", MeetDay.totalBillableTimeInHours(startTime: startTimePicker.date, endTime: endTimePicker.date, breaks: breaksSegmentedControl.selectedSegmentIndex)) as String
        breakTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", MeetDay.breakTimeInHours(breaks: breaksSegmentedControl.selectedSegmentIndex)) as String
        
        meetDayDateCell.detailTextLabel?.text = dateFormatter.string(from: meetDayDatePicker.date)
        meetDayStartTimeCell.detailTextLabel?.text = timeFormatter.string(from: startTimePicker.date)
        meetDayEndTimeCell.detailTextLabel?.text = timeFormatter.string(from: endTimePicker.date)
        navigationItem.title = dateFormatter.string(from: meetDayDatePicker.date)
    }
    
    @IBAction func numberOfBreaksChanged(_ sender: UISegmentedControl) {
        meetDay?.breaks = sender.selectedSegmentIndex
        updateUILabels()
    }
    
    @IBAction func meetDayStartTimeChanged(_ sender: UIDatePicker) {
        if sender.date >= endTimePicker.date{
            endTimePicker.setDate(sender.date + 15 * 60, animated: true)
        }
        
        updateUILabels()
    }
    
    @IBAction func meetDayEndTimeChanged(_ sender: UIDatePicker) {
        if sender.date <= startTimePicker.date{
            startTimePicker.setDate(sender.date - 15 * 60, animated: true)
        }
        
        updateUILabels()
    }
    
    @IBAction func meetDayDateChanged(_ sender: UIDatePicker) {
        var components = DateComponents()
        let newDate = meetDayDatePicker.date
        
        let day = Calendar.current.component(Calendar.Component.day, from: newDate)
        let month = Calendar.current.component(Calendar.Component.month, from: newDate)
        let year = Calendar.current.component(Calendar.Component.year, from: newDate)
        
        components.day = day
        components.month = month
        components.year = year
        
        startTimePicker.setDate(Calendar.current.date(byAdding: components, to: startTimePicker.date)!, animated: false)
        endTimePicker.setDate(Calendar.current.date(byAdding: components, to: endTimePicker.date)!, animated: false)
        
        updateUILabels()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            var updateTable = false
            
            if (indexPath.row == 0){
                showMeetDayDatePicker = !showMeetDayDatePicker
                if showMeetDayDatePicker{
                    showMeetDayStartTimePicker = false
                    showMeetDayEndTimePicker = false
                }
                updateTable = true
            }
            else if (indexPath.row == 2){
                showMeetDayStartTimePicker = !showMeetDayStartTimePicker
                if showMeetDayStartTimePicker{
                    showMeetDayDatePicker = false
                    showMeetDayEndTimePicker = false
                }
                updateTable = true
            }
            else if (indexPath.row == 4){
                showMeetDayEndTimePicker = !showMeetDayEndTimePicker
                
                if showMeetDayEndTimePicker{
                    showMeetDayDatePicker = false
                    showMeetDayStartTimePicker = false
                }
                updateTable = true
            }
            
            if updateTable {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0 && (!showMeetDayDatePicker && indexPath.row == 1) || (!showMeetDayStartTimePicker && indexPath.row == 3) || !showMeetDayEndTimePicker && indexPath.row == 5) {
            return 0
        }
        else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
}
