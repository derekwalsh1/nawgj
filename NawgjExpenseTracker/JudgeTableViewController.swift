//
//  JudgeTableViewController.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/16/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit
import os.log

class JudgeTableViewController: UITableViewController {
    
    //MARK: Properties
    var meet : Meet?
    var numberFormatter : NumberFormatter = NumberFormatter()
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        meet = MeetListManager.GetInstance().getSelectedMeet()
        meet!.judges = (meet?.judges.sorted(by: {$0.name < $1.name}))!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (meet?.judges.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Configure the cell...
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeTableCell", for: indexPath) as? JudgeTableViewCell  else {
            fatalError("The dequeued cell is not an instance of JudgeTableViewCell.")
        }
        
        // Fetches the appropriate meet for the data source layout.
        let judge = meet?.judges[indexPath.row]
        cell.textLabel?.text = (judge?.name)! + " (\(judge!.level.description))"
        cell.detailTextLabel?.text = String(format: " Fees: %@ | Expenses: %@", numberFormatter.string(from: judge!.totalFees() as NSNumber)!, numberFormatter.string(from: judge!.totalExpenses() as NSNumber)!)
        if (judge?.isPaid())!{
            cell.backgroundColor = UIColor.seafoam()
            //cell.imageView?.image = UIImage(systemName: "checkmark.rectangle.fill")
        }
        else{
            cell.backgroundColor = .systemBackground
            //cell.imageView?.image = UIImage(systemName: "rectangle")
        }

        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meet?.judges.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class
            // insert it into the array, and add a new row to the table view
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        super.prepare(for: segue, sender: sender)
        
        switch(segue.identifier ?? "") {
        case "AddItem":
            let newJudge = Judge(name: "New Judge", level: .FourToEight, fees: Array<Fee>())!
            let newIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0), section: 0)
            MeetListManager.GetInstance().addJudge(judge: newJudge)
            MeetListManager.GetInstance().selectJudgeAt(index: newIndexPath.row)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
            
        case "ShowDetail":
            guard let selectedJudgeCell = sender as? JudgeTableViewCell, let indexPath = tableView.indexPath(for: selectedJudgeCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            MeetListManager.GetInstance().selectJudgeAt(index: indexPath.row)
            
        default:
            break
        }
    }
    
    //MARK: Actions
    @IBAction func unwindToJudgeList(sender: UIStoryboardSegue) {
        tableView.reloadData()
        tableView.setNeedsLayout()
    }
}

extension UIColor {

        class func cantaloupe() -> UIColor {
            return UIColor(red:255/255, green:204/255, blue:102/255, alpha:1.0)
        }
        class func honeydew() -> UIColor {
            return UIColor(red:204/255, green:255/255, blue:102/255, alpha:1.0)
        }
        class func spindrift() -> UIColor {
            return UIColor(red:102/255, green:255/255, blue:204/255, alpha:1.0)
        }
        class func sky() -> UIColor {
            return UIColor(red:102/255, green:204/255, blue:255/255, alpha:1.0)
        }
        class func lavender() -> UIColor {
            return UIColor(red:204/255, green:102/255, blue:255/255, alpha:1.0)
        }
        class func carnation() -> UIColor {
            return UIColor(red:255/255, green:111/255, blue:207/255, alpha:1.0)
        }
        class func licorice() -> UIColor {
            return UIColor(red:0/255, green:0/255, blue:0/255, alpha:1.0)
        }
        class func snow() -> UIColor {
            return UIColor(red:255/255, green:255/255, blue:255/255, alpha:1.0)
        }
        class func salmon() -> UIColor {
            return UIColor(red:255/255, green:102/255, blue:102/255, alpha:1.0)
        }
        class func banana() -> UIColor {
            return UIColor(red:255/255, green:255/255, blue:102/255, alpha:1.0)
        }
        class func flora() -> UIColor {
            return UIColor(red:102/255, green:255/255, blue:102/255, alpha:1.0)
        }
        class func ice() -> UIColor {
            return UIColor(red:102/255, green:255/255, blue:255/255, alpha:1.0)
        }
        class func orchid() -> UIColor {
            return UIColor(red:102/255, green:102/255, blue:255/255, alpha:1.0)
        }
        class func bubblegum() -> UIColor {
            return UIColor(red:255/255, green:102/255, blue:255/255, alpha:1.0)
        }
        class func lead() -> UIColor {
            return UIColor(red:25/255, green:25/255, blue:25/255, alpha:1.0)
        }
        class func mercury() -> UIColor {
            return UIColor(red:230/255, green:230/255, blue:230/255, alpha:1.0)
        }
        class func tangerine() -> UIColor {
            return UIColor(red:255/255, green:128/255, blue:0/255, alpha:1.0)
        }
        class func lime() -> UIColor {
            return UIColor(red:128/255, green:255/255, blue:0/255, alpha:1.0)
        }
        class func seafoam() -> UIColor {
            return UIColor(red:0/255, green:255/255, blue:128/255, alpha:0.5)
        }
        class func aqua() -> UIColor {
            return UIColor(red:0/255, green:128/255, blue:255/255, alpha:1.0)
        }
        class func grape() -> UIColor {
            return UIColor(red:128/255, green:0/255, blue:255/255, alpha:1.0)
        }
        class func strawberry() -> UIColor {
            return UIColor(red:255/255, green:0/255, blue:128/255, alpha:1.0)
        }
        class func tungsten() -> UIColor {
            return UIColor(red:51/255, green:51/255, blue:51/255, alpha:1.0)
        }
        class func silver() -> UIColor {
            return UIColor(red:204/255, green:204/255, blue:204/255, alpha:1.0)
        }
        class func maraschino() -> UIColor {
            return UIColor(red:255/255, green:0/255, blue:0/255, alpha:1.0)
        }
        class func lemon() -> UIColor {
            return UIColor(red:255/255, green:255/255, blue:0/255, alpha:1.0)
        }
        class func spring() -> UIColor {
            return UIColor(red:0/255, green:255/255, blue:0/255, alpha:1.0)
        }
        class func turquoise() -> UIColor {
            return UIColor(red:0/255, green:255/255, blue:255/255, alpha:1.0)
        }
        class func blueberry() -> UIColor {
            return UIColor(red:0/255, green:0/255, blue:255/255, alpha:1.0)
        }
        class func magenta() -> UIColor {
            return UIColor(red:255/255, green:0/255, blue:255/255, alpha:1.0)
        }
        class func iron() -> UIColor {
            return UIColor(red:76/255, green:76/255, blue:76/255, alpha:1.0)
        }
        class func magnesium() -> UIColor {
            return UIColor(red:179/255, green:179/255, blue:179/255, alpha:1.0)
        }
        class func mocha() -> UIColor {
            return UIColor(red:128/255, green:64/255, blue:0/255, alpha:1.0)
        }
        class func fern() -> UIColor {
            return UIColor(red:64/255, green:128/255, blue:0/255, alpha:1.0)
        }
        class func moss() -> UIColor {
            return UIColor(red:0/255, green:128/255, blue:64/255, alpha:1.0)
        }
        class func ocean() -> UIColor {
            return UIColor(red:0/255, green:64/255, blue:128/255, alpha:1.0)
        }
        class func eggplant() -> UIColor {
            return UIColor(red:64/255, green:0/255, blue:128/255, alpha:1.0)
        }
        class func maroon() -> UIColor {
            return UIColor(red:128/255, green:0/255, blue:64/255, alpha:1.0)
        }
        class func steel() -> UIColor {
            return UIColor(red:102/255, green:102/255, blue:102/255, alpha:1.0)
        }
        class func aluminium() -> UIColor {
            return UIColor(red:153/255, green:153/255, blue:153/255, alpha:1.0)
        }
        class func cayenne() -> UIColor {
            return UIColor(red:128/255, green:0/255, blue:0/255, alpha:1.0)
        }
        class func asparagus() -> UIColor {
            return UIColor(red:128/255, green:120/255, blue:0/255, alpha:1.0)
        }
        class func clover() -> UIColor {
            return UIColor(red:0/255, green:128/255, blue:0/255, alpha:1.0)
        }
        class func teal() -> UIColor {
            return UIColor(red:0/255, green:128/255, blue:128/255, alpha:1.0)
        }
        class func midnight() -> UIColor {
            return UIColor(red:0/255, green:0/255, blue:128/255, alpha:1.0)
        }
        class func plum() -> UIColor {
            return UIColor(red:128/255, green:0/255, blue:128/255, alpha:1.0)
        }
        class func tin() -> UIColor {
            return UIColor(red:127/255, green:127/255, blue:127/255, alpha:1.0)
        }
        class func nickel() -> UIColor {
            return UIColor(red:128/255, green:128/255, blue:128/255, alpha:1.0)
        }
}

