//
//  BalanceView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 01/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit

class BalanceView : UIView {
    
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var rightAmountConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightArrowImage: UIImageView!
    
    fileprivate var selected = false
    
    func setSelected(_ selected: Bool, animated: Bool) {
        guard self.selected != selected else { return }
        
        self.selected = selected
        
        self.rightAmountConstraint.constant = selected ? 0.0 : 20.0
        let block = {
            self.rightArrowImage.alpha = selected ? 0.0 : 1.0
            self.layoutIfNeeded()
        }
        
        guard animated else {
            block()
            return
        }
        
        UIView.animate(withDuration: TimeInterval(UINavigationControllerHideShowBarDuration)) {
            block()
        }
    }
}
