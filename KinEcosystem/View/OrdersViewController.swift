//
//  OrdersViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class OrdersViewController: KinNavigationChildController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Transaction History"

        let buttonEdit: UIButton = UIButton(type: .custom) as UIButton
        buttonEdit.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        buttonEdit.setImage(UIImage(named: "whatsKin", in: Bundle.ecosystem, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal), for: .normal)
        buttonEdit.addTarget(self, action: #selector(didTapInfo), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: buttonEdit)
        
    }
    
    @objc fileprivate func didTapInfo(sender: Any?) {

    }

}
