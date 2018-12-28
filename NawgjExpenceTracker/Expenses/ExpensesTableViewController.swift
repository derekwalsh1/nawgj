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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateExpenseLabels()
        
    }

    func updateExpenseLabels(){
        for expense in (judge?.expenses)!{
            switch expense.type{
            case .Airfare:
                airfareCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
                break
            case .Toll:
                tollsCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
                break
            case .Meals:
                mealsCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
                break
            case .Transportation:
                transportationCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
                break
            case .Other:
                otherCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
                break
            case .Mileage:
                mileageCell.detailTextLabel?.text = String(format: "%0.1f miles ($%0.2f)", expense.amount, expense.amount * (meet?.mileageRate)!)
                break
            case .Parking:
                parkingCell.detailTextLabel?.text = String(format: "$%0.2f", expense.amount)
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
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Transportation})
                break
            case "ShowParkingExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Parking})
                break
            case "ShowAirfareExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Airfare})
                break
            case "ShowOtherExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Other})
                break
            case "ShowMealsExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Meals})
                break
            case "ShowMileageExpenseDetails":
                selectedExpense = judge?.expenses.first(where:{$0.type == Expense.ExpenseType.Mileage})
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
            
            updateExpenseLabels()
            
            tableView.reloadRows(at: [selectedIndexPath], with: .none)
        }
    }
}
