//
//  MeetDayDetailTableViewCell.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 11/19/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit

class MeetDayDateTimeCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    //MARK: Properties
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
