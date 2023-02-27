//
//  MeetViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import PDFKit
import os.log

class MeetDetailViewController: UITableViewController, UITextFieldDelegate{
    
    //MARK: Properties
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var meetDatePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var meetDateCell: UITableViewCell!
    @IBOutlet weak var meetLocationField: UITextField!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var summaryTableView: UITableView!
    @IBOutlet weak var exportMeetButton: UIButton!
    @IBOutlet weak var generateReportButton: UIButton!
    
    /*
     This value is either passed by `MeetTableViewController` in `prepare(for:sender:)` or constructed as part of adding a new meal.
     */
    var meet: Meet = Meet(name: "New Meet", startDate: Date())!
    var dateFormatter : DateFormatter = DateFormatter()
    var numberFormatter : NumberFormatter = NumberFormatter()
    var showMeetDatePicker : Bool = false
    var summaryTableDelegate : MeetSummaryTableViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        meet = MeetListManager.GetInstance().getSelectedMeet()!
        
        for textField in [nameTextField, descriptionTextField, meetLocationField] {
            textField!.delegate = self
        }
        
        for label in [nameLabel, locationLabel, descriptionLabel]{
            label?.textColor = self.view.tintColor
        }
        
        summaryTableDelegate = MeetSummaryTableViewDelegate(meet: meet)
        summaryTableView.dataSource = summaryTableDelegate
        summaryTableView.delegate = summaryTableDelegate
        
        dateFormatter.dateStyle = .medium
        numberFormatter.numberStyle = .currency
        meetDateCell.textLabel?.textColor = self.view.tintColor
        meetDateCell.detailTextLabel?.text = dateFormatter.string(from: meet.startDate)
        
        // Set up views if editing an existing Meet.
        navigationItem.title = meet.name
        navigationItem.backBarButtonItem?.title = "Meet List"
        nameTextField.text = meet.name
        meetDatePicker.date = meet.startDate
        descriptionTextField.text = meet.meetDescription.trimmingCharacters(in: .whitespaces)
        meetLocationField.text = meet.location.trimmingCharacters(in: .whitespaces)
        
        if meet.name == "New Meet"{
            nameTextField.text = ""
        }
        
        if nameTextField.text == ""{
            nameTextField.becomeFirstResponder()
        }
        else if meetLocationField.text == ""{
            meetLocationField.becomeFirstResponder()
        }
        else if descriptionTextField.text == ""{
            descriptionTextField.becomeFirstResponder()
        }
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        switch indexPath.section {
        case 1:
            cell.detailTextLabel?.text = meetDaysDetailText()
        case 2:
            cell.detailTextLabel?.text = judgeDetailText()
        
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section
        let row = indexPath.row
        
        switch(section){
        case 0:
            switch(row){
            case 3:
                showMeetDatePicker = !showMeetDatePicker
                tableView.beginUpdates()
                tableView.endUpdates()
            
            default:
                break
            }
        
        case 1:
            self.performSegue(withIdentifier: "ShowMeetDayTable", sender: self)
        case 2:
            self.performSegue(withIdentifier: "ShowJudgeTable", sender: self)

        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0 && (!showMeetDatePicker && indexPath.row == 4)) {
            return 0
        }
        else if (indexPath.section == 3 && indexPath.row == 0){
            let numberOfCells : CGFloat = CGFloat((meet.judges.count) + 1)
            let numberOfSections : CGFloat = CGFloat(meet.days.count)
            let rowHeight = summaryTableView!.estimatedRowHeight
            let headerHeight = summaryTableView!.estimatedSectionHeaderHeight
            let footerHeight = summaryTableView!.estimatedSectionFooterHeight
            
            return (numberOfSections * (headerHeight + footerHeight)) + ((numberOfCells * numberOfSections) * rowHeight) + 200
        }
        else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func nameTextFieldEditingChanged(_ sender: UITextField) {
        navigationItem.title = sender.text
    }
    
    // MARK: Meet date selection
    
    @IBAction func meetDateChanged(_ sender: UIDatePicker) {
        meetDateCell.detailTextLabel?.text = dateFormatter.string(from: meetDatePicker.date)
    }
    
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        updateSelectedMeet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateSelectedMeet()
        super.viewWillDisappear(animated)
    }
    
    func updateSelectedMeet(){
        meet.name = nameTextField.text ?? "New Meet"
        meet.startDate = meetDatePicker.date
        meet.meetDescription = descriptionTextField.text ?? ""
        meet.location = meetLocationField.text ?? ""
        
        MeetListManager.GetInstance().updateSelectedMeetWith(meet: meet)
    }
    
    func meetDaysDetailText() -> String {
        let meetDayText = meet.days.count == 1 ? "Day" : "Days"
        return "\(meet.days.count) \(meetDayText) - \(meet.billableMeetHours()) Hours"
    }
    
    func judgeDetailText() -> String {
        let judgeText = meet.judges.count == 1 ? "Judge" : "Judges"
        return "\(meet.judges.count) \(judgeText) - " + numberFormatter.string(from: meet.totalJudgeFeesAndExpenses() as NSNumber)!
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetDetails(sender: UIStoryboardSegue) {
        if let delegate = summaryTableDelegate, let meet = MeetListManager.GetInstance().getSelectedMeet(){
            delegate.meet = meet
        }
        tableView.reloadData()
        summaryTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dataToFile(fileName: String) -> URL? {
        do{
            let newURL = JudgeListManager.DocumentsDirectory.appendingPathComponent(fileName)
            var encodedData = try JSONEncoder().encode(meet)
            let meetFromData = try JSONDecoder().decode(Meet.self, from: encodedData) as Meet
            encodedData = try JSONEncoder().encode(meetFromData)
            try encodedData.write(to: newURL)
            
            return newURL
        } catch{
            os_log("Failed to convert meet to JSON format", log: OSLog.default, type: .error)
            return nil
        }
    }
    
    func meetDataToJSONString() -> Data? {
        do{
            let encodedData = try JSONEncoder().encode(meet)
            return encodedData
        } catch{
            os_log("Failed to convert meet to JSON format", log: OSLog.default, type: .error)
            return nil
        }
    }
    
    @IBAction func exportMeetButtonClicked(_ sender: UIButton) {
        //let jsonData = meetDataToJSONString()
        let file = dataToFile(fileName: "ExportedMeet.JSON")
        
        // Create the Array which includes the files you want to share
        var dataToShare = [Any]()

        // Add the path of the file to the Array
        dataToShare.append(file!)

        // Make the activityViewContoller which shows the share-view
        let activityViewController = UIActivityViewController(activityItems: dataToShare, applicationActivities: nil)
        activityViewController.isModalInPresentation = true
        if let popOver = activityViewController.popoverPresentationController {
            popOver.sourceView = exportMeetButton
            popOver.sourceRect = sender.bounds
            popOver.permittedArrowDirections = []
            popOver.canOverlapSourceViewRect = true
        }
        
        // Show the share-view
        self.present(activityViewController, animated: true, completion: nil)
    }
}

