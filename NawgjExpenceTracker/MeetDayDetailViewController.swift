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
    @IBOutlet weak var meetDatePicker: UIDatePicker!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var breaksSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var billableTimeLabel: UILabel!
    @IBOutlet weak var breakTimeLabel: UILabel!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)`
     or constructed as part of adding a new meal.
     */
    var meetDay: MeetDay?
    var formatter : DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatter.dateFormat = "dd-MMM-yyyy"
        
        // Set up views if editing an existing Meet day.
        if let meetDay = meetDay {
            navigationItem.title = meetDay.name
            totalTimeLabel.text = NSString(format: "%.2f", meetDay.totalTime!) as String
            billableTimeLabel.text = NSString(format: "%.2f", meetDay.billableTime!) as String
            breakTimeLabel.text = NSString(format: "%.2f", meetDay.breakTime!) as String
            
            // Round each date down to the nearest quarter hour
            let calendar = Calendar.current
            var hour = calendar.component(.hour, from: meetDay.meetDate)
            var minute = calendar.component(.minute, from: meetDay.meetDate)
            var floorMinute = minute - (minute % 15)
            meetDatePicker.date = calendar.date(bySettingHour: hour,
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
            
            breaksSegmentedControl.selectedSegmentIndex = meetDay.breaks - 1
        }
        else{
            let meetDate = Date()
            meetDatePicker.setDate(meetDate, animated: false)

            let startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: meetDate)
            startTimePicker.setDate(startTime!, animated: false)
            
            let endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: meetDate)
            endTimePicker.setDate(endTime!, animated: false)
            
            navigationItem.title = formatter.string(from: meetDate)
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
        if let button = sender as? UIBarButtonItem{
            if button === doneButton {
                meetDay?.meetDate = meetDatePicker.date
                meetDay?.startTime = startTimePicker.date
                meetDay?.endTime = endTimePicker.date
                meetDay?.breaks = breaksSegmentedControl.selectedSegmentIndex + 1
                meetDay?.name = formatter.string(from: (meetDay?.meetDate)!)
            }
            else
            {
                return
            }
        }
    }
    
    func updateUILabels()
    {
        let totalTime = Float(endTimePicker.date.timeIntervalSince(startTimePicker.date))
        let totalTimeHours = totalTime / 3600
        let breakTime = Float(breaksSegmentedControl.selectedSegmentIndex + 1) * MeetDay.BREAK_TIME_HOURS
        let billingTime = max(MeetDay.MIN_BILLING_HOURS, totalTimeHours - breakTime)
        
        totalTimeLabel.text = NSString(format: "%.2f", totalTimeHours) as String
        billableTimeLabel.text = NSString(format: "%.2f", billingTime) as String
        breakTimeLabel.text = NSString(format: "%.2f", breakTime) as String
    }
    
    @IBAction func numberOfBreaksChanged(_ sender: UISegmentedControl) {
        meetDay?.breaks = sender.selectedSegmentIndex + 1
        updateUILabels()
    }
    
    @IBAction func startTimeChanged(_ sender: UIDatePicker) {
        if sender.date >= endTimePicker.date{
            endTimePicker.setDate(sender.date + 15 * 60, animated: true)
        }
        
        updateUILabels()
    }
    
    @IBAction func endTimeChanged(_ sender: UIDatePicker) {
        if sender.date <= startTimePicker.date{
            startTimePicker.setDate(sender.date - 15 * 60, animated: true)
        }
        
        updateUILabels()
    }
    
    @IBAction func meetDateChanged(_ sender: UIDatePicker) {
        navigationItem.title = formatter.string(from: sender.date)
        var components = DateComponents()
        let newDate = meetDatePicker.date
        
        let day = Calendar.current.component(Calendar.Component.day, from: newDate)
        let month = Calendar.current.component(Calendar.Component.month, from: newDate)
        let year = Calendar.current.component(Calendar.Component.year, from: newDate)
        
        components.day = day
        components.month = month
        components.year = year
        
        startTimePicker.setDate(Calendar.current.date(byAdding: components, to: startTimePicker.date)!, animated: false)
        endTimePicker.setDate(Calendar.current.date(byAdding: components, to: endTimePicker.date)!, animated: false)
    }
}
