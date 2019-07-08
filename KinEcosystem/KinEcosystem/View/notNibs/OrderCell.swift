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
    @IBOutlet weak var timelineView: OrderCellTimelineView!
    
    var last: Bool? {
        didSet {
            if isAwake {
                timelineView.last = last
            }
        }
    }
    
    var first: Bool? {
        didSet {
            if isAwake {
                timelineView.first = first
            }
        }
    }
    
    var icon: UIImage? {
        didSet {
            if isAwake {
                timelineView.icon = icon
            }
        }
    }
    
    
    var isAwake = false
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if let last = last, let first = first, let icon = icon {
            timelineView.last = last
            timelineView.icon = icon
            timelineView.first = first
        }
        isAwake = true
    }
    
    
    
}
