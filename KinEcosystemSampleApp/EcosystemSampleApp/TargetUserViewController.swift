//
//  PayToViewController.swift
//  EcosystemSampleApp
//
//  Created by Elazar Yifrach on 16/09/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit


class TargetUserViewController: UIViewController, UITextFieldDelegate {
    
    var selectBlock: ((String) -> ())?
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var textfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nextButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPayment))
    }
    
    
    @IBAction func uidChanged(_ sender: Any) {
        nextButton.isEnabled = (sender as! UITextField).hasText
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        defer {
            self.dismiss(animated: true)
        }
        selectBlock?(textfield.text!)
    }
    
    @objc func cancelPayment() {
        self.dismiss(animated: true)
    }
}

