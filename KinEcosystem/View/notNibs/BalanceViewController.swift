//
//  BalanceViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 04/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class BalanceViewController: UIViewController {

    var core: Core!
    @IBOutlet weak var balanceAmount: UILabel!
    @IBOutlet weak var balance: UILabel!
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
            self.view.layoutIfNeeded()
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
