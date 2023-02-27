//
//  ExpensesTableViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/9/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//
import UIKit
import os.log

class ExpensesTableViewController: UITableViewController {
    
    @IBOutlet weak var mileageCell: UITableViewCell!
    @IBOutlet weak var mealsCell: UITableViewCell!
    @IBOutlet weak var tollsCell: UITableViewCell!
    @IBOutlet weak var airfareCell: UITableViewCell!
    @IBOutlet weak var transportationCell: UITableViewCell!
    @IBOutlet weak var parkingCell: UITableViewCell!
    @IBOutlet weak var lodgingCell: UITableViewCell!
    @IBOutlet weak var otherCell: UITableViewCell!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    //MARK: Properties
    var judge : Judge?
    var meet : Meet?
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .currency
        
        meet = MeetListManager.GetInstance().getSelectedMeet()
        judge = MeetListManager.GetInstance().getSelectedJudge()
        
        if let judge = judge{
            backButton.title = judge.name
        }
        updateExpenseLabels()
    }

    func updateExpenseLabels(){
        for expense in (judge?.expenses)!{
            switch expense.type{
            case .Airfare:
                airfareCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Toll:
                tollsCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Meals:
                mealsCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Transportation:
                transportationCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Other:
                otherCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Mileage:
                mileageCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Lodging:
                lodgingCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
            case .Parking:
                parkingCell.detailTextLabel?.text = numberFormatter.string(from: expense.getExpenseTotal() as NSNumber)!
                break
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
        return false
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        var selectedExpenseIndex : Int?
        
        switch(segue.identifier){
        case "ShowTollsExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Toll})
            break
        case "ShowTransportationExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Transportation})
            break
        case "ShowParkingExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Parking})
            break
        case "ShowAirfareExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Airfare})
            break
        case "ShowOtherExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Other})
            if(selectedExpenseIndex == nil){
                judge?.expenses.append(Expense(type: .Other, date: meet?.startDate ?? Date())!)
                selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Other})
            }
            break
        case "ShowMealsExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Meals})
            break
        case "ShowMileageExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Mileage})
            break
        case "ShowLodgingExpenseDetails":
            selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Lodging})
            if(selectedExpenseIndex == nil){
                judge?.expenses.append(Expense(type: .Lodging, date: meet?.startDate ?? Date())!)
                selectedExpenseIndex = judge?.expenses.firstIndex(where:{$0.type == .Lodging})
            }
            break
        default:
            break
        }
        
        if let index = selectedExpenseIndex{
            MeetListManager.GetInstance().selectExpenseAt(index: index)
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToExpenseList(sender: UIStoryboardSegue) {
        tableView.reloadData()
        updateExpenseLabels()
    }
}
