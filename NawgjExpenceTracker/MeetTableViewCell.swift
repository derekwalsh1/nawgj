//
//  MeetTableViewCell.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/22/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//

import UIKit

class MeetTableViewCell: UITableViewCell {

    //MARK: Properties
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
