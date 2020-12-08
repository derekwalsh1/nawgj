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
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem!
    
    //MARK: Properties
    @IBOutlet weak var meetDayDateCell: UITableViewCell!
    @IBOutlet weak var meetDayDatePicker: UIDatePicker!
    @IBOutlet weak var meetDayStartTimeCell: UITableViewCell!
    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var meetDayEndTimeCell: UITableViewCell!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var breaksSegmentedControl: UISegmentedControl!
    @IBOutlet weak var numberOfBreaksLabel: UILabel!
    @IBOutlet weak var breakTimeLabel: UILabel!
    @IBOutlet weak var breakTimeValueLabel: UILabel!
    @IBOutlet weak var breakTimeSlider: UISlider!
    
    @IBOutlet weak var totalTimeCell: UITableViewCell!
    @IBOutlet weak var billableTimeCell: UITableViewCell!
    @IBOutlet weak var breakTimeCell: UITableViewCell!
    
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
    
    var presentingInAddDayMode : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        timeFormatter.dateFormat = "h:mm a"
        
        meetDayDateCell.textLabel?.textColor = self.view.tintColor
        meetDayStartTimeCell.textLabel?.textColor = self.view.tintColor
        meetDayEndTimeCell.textLabel?.textColor = self.view.tintColor
        numberOfBreaksLabel.textColor = self.view.tintColor
        breakTimeLabel.textColor = self.view.tintColor
        
        totalTimeCell.textLabel?.textColor = self.view.tintColor
        billableTimeCell.textLabel?.textColor = self.view.tintColor
        breakTimeCell.textLabel?.textColor = self.view.tintColor
        
        if presentingInAddDayMode{
            os_log("Presenting in Add Meet Day mode", log: OSLog.default, type: .debug)
            self.navigationItem.title = "Add Meet Day"
            self.navigationItem.leftBarButtonItem?.title = "Add"
            doneBarButton.title = "Add"
            if let meet = MeetListManager.GetInstance().getSelectedMeet(){
                if meet.days.count > 0{
                    self.navigationItem.prompt = "You are adding a new day to the \"" + meet.name + "\" meet"
                    // Grab the last meet day and use the data from that meet day as the
                    // starting point for the new meet day. Just increment the start date
                    // by 1 day
                    let lastMeetDayAlreadyAdded = meet.days[meet.days.count - 1]
                    meetDay = MeetDay(meetDate: lastMeetDayAlreadyAdded.meetDate.addingTimeInterval(24*60*60), startTime: lastMeetDayAlreadyAdded.startTime, endTime: lastMeetDayAlreadyAdded.endTime, breaks: lastMeetDayAlreadyAdded.breaks)
                }
                else{
                    let units: Set<Calendar.Component> = [.year, .month, .day, .hour]
                    var components = Calendar.current.dateComponents(units, from: Date())
                    components.hour = 7
                    let startTime = Calendar.current.date(from: components)
                    components.hour = 17
                    let endTime = Calendar.current.date(from: components)
                    
                    meetDay = MeetDay(meetDate: meet.startDate, startTime: startTime!, endTime: endTime!, breaks: 2)
                }
            }
            
            if let meetDay = meetDay{
                meetDayDatePicker.date = meetDay.meetDate
                startTimePicker.date = meetDay.startTime
                endTimePicker.date = meetDay.endTime
                breaksSegmentedControl.selectedSegmentIndex = meetDay.breaks
                breakTimeSlider.value = Float(meetDay.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS);
                
                endTimePicker.minimumDate = startTimePicker.date
                updateUILabels(meetDay: meetDay)
            }
        }
        else{
            os_log("Presenting in Edit Meet Day mode", log: OSLog.default, type: .debug)
            self.title = "Meet Day Details"
            if let meet = MeetListManager.GetInstance().getSelectedMeet(){
                self.navigationItem.prompt = "You are editing an existing meet day in the \"" + meet.name + "\" meet"
            }
            meetDay = MeetListManager.GetInstance().getSelectedMeetDay()
            
            if let meetDay = meetDay{
                meetDayDatePicker.date = meetDay.meetDate
                startTimePicker.date = meetDay.startTime
                endTimePicker.date = meetDay.endTime
                breakTimeSlider.value = Float(meetDay.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS);
                
                breaksSegmentedControl.selectedSegmentIndex = meetDay.breaks
                
                if let meet = MeetListManager.GetInstance().getSelectedMeet(){
                    meetDayDatePicker.minimumDate = meet.startDate
                }
                updateUILabels(meetDay: meetDay)
            }
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
    
    func updateUILabels(meetDay : MeetDay)
    {
        totalTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", meetDay.totalTimeInHours(startTime: startTimePicker.date, endTime: endTimePicker.date)) as String
        billableTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", meetDay.totalBillableTimeInHours(startTime: startTimePicker.date, endTime: endTimePicker.date, breaks: breaksSegmentedControl.selectedSegmentIndex)) as String
        breakTimeCell.detailTextLabel?.text = NSString(format: "%.2f hours", meetDay.breakTimeInHours()) as String
        
        meetDayDateCell.detailTextLabel?.text = dateFormatter.string(from: meetDayDatePicker.date)
        meetDayStartTimeCell.detailTextLabel?.text = timeFormatter.string(from: startTimePicker.date)
        meetDayEndTimeCell.detailTextLabel?.text = timeFormatter.string(from: endTimePicker.date)
        breakTimeValueLabel.text = NSString(format: "%d mins", (meetDay.breakTimeInMins ?? MeetDay.DEFAULT_BREAK_TIME_MINS)) as String
        //navigationItem.title = dateFormatter.string(from: meetDayDatePicker.date)
    }
    
    @IBAction func numberOfBreaksChanged(_ sender: UISegmentedControl) {
        if let meetDay = meetDay{
            meetDay.breaks = sender.selectedSegmentIndex
            updateUILabels(meetDay: meetDay)
        }
    }
    
    @IBAction func meetDayStartTimeChanged(_ sender: UIDatePicker) {
        endTimePicker.minimumDate = startTimePicker.date
        if sender.date >= endTimePicker.date{
            endTimePicker.setDate(sender.date + 15 * 60, animated: true)
        }
        
        if meetDay != nil{
            updateUILabels(meetDay: meetDay!)
        }
    }
    
    @IBAction func meetDayEndTimeChanged(_ sender: UIDatePicker) {
        if meetDay != nil{
            updateUILabels(meetDay: meetDay!)
        }
    }
    
    @IBAction func meetDayDateChanged(_ sender: UIDatePicker) {
        var components = DateComponents()
        
        // Check if this date is already in the meet days
        let newDate = meetDayDatePicker.date
        
        let matchingMeetDate = MeetListManager.GetInstance().getSelectedMeet()?.days.first(where: { Calendar.current.compare($0.meetDate, to: newDate, toGranularity: .day) == .orderedSame})
        if matchingMeetDate == nil{
            let day = Calendar.current.component(Calendar.Component.day, from: newDate)
            let month = Calendar.current.component(Calendar.Component.month, from: newDate)
            let year = Calendar.current.component(Calendar.Component.year, from: newDate)
            
            components.day = day
            components.month = month
            components.year = year
            
            startTimePicker.setDate(Calendar.current.date(byAdding: components, to: startTimePicker.date)!, animated: false)
            endTimePicker.setDate(Calendar.current.date(byAdding: components, to: endTimePicker.date)!, animated: false)
            
            if meetDay != nil{
                updateUILabels(meetDay: meetDay!)
            }
        }
        else{
            meetDayDatePicker.date = (meetDay?.meetDate)!
            let alert = UIAlertController(title: "\(dateFormatter.string(from: newDate)) is already in use", message: nil, preferredStyle: .alert)
            let actionOk = UIAlertAction(title: "Ok", style: .default) { (action:UIAlertAction) in }
            alert.addAction(actionOk)
            self.present(alert, animated: true)
        }
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
    
    @IBAction func doneBarButtonClicked(_ sender: UIBarButtonItem) {
        if let meetDay = meetDay{
            meetDay.meetDate = meetDayDatePicker.date
            meetDay.startTime = startTimePicker.date
            meetDay.endTime = endTimePicker.date
            meetDay.breaks = breaksSegmentedControl.selectedSegmentIndex
            
            if presentingInAddDayMode{
                MeetListManager.GetInstance().addMeetDay(meetDay: meetDay)
            }
            else{
                MeetListManager.GetInstance().updateSelectedMeetDayWith(meetDay: meetDay)
            }
        }
        
        performSegue(withIdentifier: "unwindToDayList", sender: self)
    }
    
    @IBAction func cancelBarButtonItemClicked(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "unwindToDayList", sender: self)
    }
    
    func updateDoneButtonState(){
        // Done button should be enable if the day settings are valid. This means that the day must
        // be unique for the meet, i.e. the date of the meet day must not be already used. Other than
        // that, the UI prevents all other invalid settings from occurring but we check anyway. The
        // start time needs to be before the end time and the number of breaks can be 0, 1, 2 or 3 only.
        // A meet day really only has 4 attributes
        //   (1) A Date
        //   (2) A Start Time
        //   (3) An End TIme
        //   (4) Number of 30 minute breaks
    }
    
    @IBAction func brakeTimeSliderValueChanged(_ sender: UISlider) {
        if let meetDay = meetDay{
            meetDay.breakTimeInMins = Int(sender.value)
            updateUILabels(meetDay: meetDay)
        }
    }
}
