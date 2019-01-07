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
    @IBOutlet weak var otherCell: UITableViewCell!
    
    //MARK: Properties
    var judge : Judge?
    var meet : Meet?
    var numberFormatter : NumberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter.numberStyle = .currency
        
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
        
        switch(segue.identifier ?? "Unwind") {
        case "Unwind":
            break
        default:
            guard let expenseDetailsViewController = segue.destination as? ExpenseDetailsViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            var selectedExpense : Expense? = nil
            switch(segue.identifier){
            case "ShowTollsExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Toll})
                break
            case "ShowTransportationExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Transportation})
                break
            case "ShowParkingExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Parking})
                break
            case "ShowAirfareExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Airfare})
                break
            case "ShowOtherExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Other})
                break
            case "ShowMealsExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Meals})
                break
            case "ShowMileageExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == .Mileage})
                break
            default:
                break
            }
            expenseDetailsViewController.navigationItem.title = selectedExpense?.type.description
            expenseDetailsViewController.judge = judge
            expenseDetailsViewController.expense = selectedExpense!
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToExpenseList(sender: UIStoryboardSegue) {
        let sourceViewController = sender.source as? ExpenseDetailsViewController
        let expense = sourceViewController?.expense
        
        let selectedExpense = judge?.expenses.first(where:{$0.type == expense?.type})
        
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            
            // Update an existing expense.
            selectedExpense!.amount = (expense?.amount)!
            selectedExpense!.notes = (expense?.notes)!
            selectedExpense!.date = (expense?.date)!
            
            updateExpenseLabels()
            
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        }
    }
}
