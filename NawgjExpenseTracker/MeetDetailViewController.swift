//
//  MeetViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import MessageUI
import PDFKit
import os.log

class MeetDetailViewController: UITableViewController, UITextFieldDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate{
    
    //MARK: Properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var meetDatePicker: UIDatePicker!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var meetDateCell: UITableViewCell!
    @IBOutlet weak var meetLocationField: UITextField!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var summaryTableView: UITableView!
    
    
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
        nameTextField.text = meet.name
        meetDatePicker.date = meet.startDate
        descriptionTextField.text = meet.meetDescription.trimmingCharacters(in: .whitespaces)
        meetLocationField.text = meet.location.trimmingCharacters(in: .whitespaces)
        
        // Enable the Save button only if the text field has a valid meet name.
        updateSaveButtonState()
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
            
            return (numberOfSections * (headerHeight + footerHeight)) + ((numberOfCells * numberOfSections) * rowHeight)
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
        updateSaveButtonState()
    }
    
    // MARK: Meet date selection
    
    @IBAction func meetDateChanged(_ sender: UIDatePicker) {
        meetDateCell.detailTextLabel?.text = dateFormatter.string(from: meetDatePicker.date)
    }
    
    //MARK: Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Discard Changes?", message: nil, preferredStyle: .alert)
        let actionCancel = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in }
        let actionDiscard = UIAlertAction(title: "Discard Changes", style: .default) { (action:UIAlertAction) in
            let isPresentingInAddMeetMode = self.presentingViewController is UINavigationController
            
            if isPresentingInAddMeetMode {
                self.dismiss(animated: true, completion: nil)
            }
            else if let owningNavigationController = self.navigationController{
                owningNavigationController.popViewController(animated: true)
            }
            else {
                fatalError("The MeetViewController is not inside a navigation controller.")
            }        }
        alert.addAction(actionCancel)
        alert.addAction(actionDiscard)
        self.present(alert, animated: true)
    }
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        // Configure the destination view controller only when the save button is pressed.
        if let button = sender as? UIBarButtonItem{
            if button === saveButton {
                meet.name = nameTextField.text!
                meet.startDate = meetDatePicker.date
                meet.meetDescription = descriptionTextField.text!
                meet.location = meetLocationField.text!
            }
            else
            {
                guard let pdfViewController = segue.destination as? PDFViewController else{
                    fatalError("Unexpected destination when trying to navigate to PDF View")
                }
                let path = Meet.DocumentsDirectory.appendingPathComponent("MeetDetails.pdf")
                MeetPDFCreator.createPDFFrom(meet: meet, atLocation: path)
                pdfViewController.pdfURL = path
            }
        }
        else{
            switch(segue.identifier ?? "") {
            
            case "ShowJudgeTable":
                guard let judgeTableViewController = segue.destination as? JudgeTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                
                judgeTableViewController.meet = meet
            
            case "ShowMeetDayTable":
                guard let meetDayTableViewController = segue.destination as? MeetDayTableViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                meet.startDate = meetDatePicker.date
                meetDayTableViewController.meet = meet
                   
            default:
                fatalError("Unexpected Segue Identifier")
            }
        }
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
        
        let sourceViewController = sender.source as? MeetDayTableViewController
        let updatedMeet = sourceViewController?.meet
        
        if (sourceViewController != nil), (updatedMeet != nil){
            // Update an existing meet day.
            meet = updatedMeet!
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 1)).detailTextLabel?.text = meetDaysDetailText()
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 2)).detailTextLabel?.text = judgeDetailText()
            reloadSummary()
        }
    }
    
    func reloadSummary(){
        summaryTableDelegate?.meet = meet
        
        tableView.reloadData()
        tableView.setNeedsDisplay()
        
        summaryTableView.reloadData()
        summaryTableView.setNeedsDisplay()
        summaryTableView.setNeedsLayout()
        
        self.view.setNeedsDisplay()
    }
    
    //MARK: Actions
    @IBAction func unwindToMeetDetailsFromJudgeList(sender: UIStoryboardSegue) {
        
        let sourceViewController = sender.source as? JudgeTableViewController
        let updatedMeet = sourceViewController?.meet
        
        if (sourceViewController != nil), (updatedMeet != nil){
            // Update an existing meet day.
            meet = updatedMeet!
            super.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 2)).detailTextLabel?.text = judgeDetailText()
            reloadSummary()
        }
    }
    
    //MARK: Private Methods
    private func updateSaveButtonState() {
        // Disable the Save button if the text field is empty.
        saveButton.isEnabled = !(nameTextField.text ?? "").isEmpty
    }
    
    func showPDF()
    {
        let email = "derek.walsh@gmail.com"
        let path = Meet.DocumentsDirectory.appendingPathComponent("MeetDetails.pdf")
        MeetPDFCreator.createPDFFrom(meet: meet, atLocation: path)
        
        let pdfView = PDFView()
        if let document = PDFDocument(url: path) {
            pdfView.autoScales = true
            pdfView.displayMode = .singlePageContinuous
            pdfView.displayDirection = .vertical
            pdfView.document = document
        }
            
        if( MFMailComposeViewController.canSendMail()){
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients([email])
            mailComposer.setSubject("Meet Details for \(meet.name)")
            mailComposer.setMessageBody("Meet details attached", isHTML: false)
            
            try! mailComposer.addAttachmentData(NSData(contentsOf: path) as Data, mimeType: "application/pdf", fileName: "MeetReport.pdf")
            self.navigationController?.present(mailComposer, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}

