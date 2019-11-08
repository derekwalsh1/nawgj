//
//  MeetTableViewCell.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 12/20/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit

class MeetTableViewCell: UITableViewCell {
    
    //MARK: Properties
    @IBOutlet weak var locationCell: UITableViewCell!
    @IBOutlet weak var descriptionCell: UITableViewCell!
    @IBOutlet weak var hoursCell: UITableViewCell!
    @IBOutlet weak var costCell: UITableViewCell!
    @IBOutlet weak var titleLabel: UILabel!
    
    var meet : Meet?
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberFormatter.numberStyle = .currency
        dateFormatter.dateStyle = .short
        
        if meet == nil{
            _ = Meet(name: "New Meet", startDate: Date())
        }
        
        setupCellContent()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupCellContent(){
        let titleColor = self.contentView.tintColor
        for cell in [locationCell, descriptionCell, hoursCell, costCell]{
            cell?.textLabel?.textColor = titleColor
        }
        
        if let meet = meet{
            locationCell.detailTextLabel?.text = meet.location
            descriptionCell.detailTextLabel?.text = meet.meetDescription
            hoursCell.detailTextLabel?.text = String(format: "%0.2f", (meet.billableMeetHours()))
            costCell.detailTextLabel?.text = numberFormatter.string(from: meet.totalCostOfMeet() as NSNumber)!
            titleLabel.text = meet.name + " (\(dateFormatter.string(from: meet.startDate)))"
        }
        
        locationCell.setNeedsLayout()
        descriptionCell.setNeedsLayout()
        hoursCell.setNeedsLayout()
        costCell.setNeedsLayout()
    }
}
