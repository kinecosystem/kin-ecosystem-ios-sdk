//
//  OrderCell.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class OrderCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var amount: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var timelineView: OrderCellTimelineView!
    
    var last: Bool? {
        didSet {
            if isAwake {
                timelineView.last = last
            }
        }
    }
    var color: UIColor? {
        didSet {
            if isAwake {
                timelineView.color = color
            }
        }
    }
    
    
    var isAwake = false
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let last = last, let color = color {
            timelineView.last = last
            timelineView.color = color
        }
        isAwake = true
    }
    
    
    
}
