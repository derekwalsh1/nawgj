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
    @IBOutlet weak var titelLabel: UILabel!
    
    var meet : Meet?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if meet == nil{
            _ = Meet(name: "New Meet", startDate: Date())
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setupCellContent(){
        let titleColor = self.contentView.tintColor
        
        locationCell.detailTextLabel?.text = meet?.location
        descriptionCell.detailTextLabel?.text = meet?.meetDescription
        hoursCell.detailTextLabel?.text = String(format: "%0.2f", (meet?.billableMeetHours())!)
        costCell.detailTextLabel?.text = String(format: "$%0.2f", (meet?.totalCostOfMeet())!)
        
        for cell in [locationCell, descriptionCell, hoursCell, costCell]{
            cell?.textLabel?.textColor = titleColor
        }
        
        titelLabel.text = meet?.name
    }
    
}
