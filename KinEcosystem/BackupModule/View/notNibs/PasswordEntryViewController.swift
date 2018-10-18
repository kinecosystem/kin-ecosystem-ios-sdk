//
//  PasswordEntryViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

protocol PasswordEntryDelegate {
    func validatePasswordConformance(_ password: String) -> Bool
}

@available(iOS 9.0, *)
class PasswordEntryViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordInfo: UILabel!
    @IBOutlet weak var passwordInput1: UITextField!
    @IBOutlet weak var passwordInput2: UITextField!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmTick: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    
    var viewModel = PasswordEntryViewModel()
    var delegate: PasswordEntryDelegate?
    
    var kbObservers = [NSObjectProtocol]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let paddingView1 = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: passwordInput1.frame.height))
        let paddingView2 = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 22.0, height: passwordInput2.frame.height))
        title = "kinecosystem_keep_kin_safe".localized()
        passwordInput1.layer.borderWidth = 1.0
        passwordInput1.layer.borderColor = UIColor.kinPrimaryBlue.cgColor
        passwordInput1.layer.cornerRadius = 20.0
        passwordInput1.leftView = paddingView1
        passwordInput1.leftViewMode = .always
        passwordInput2.leftView = paddingView2
        passwordInput2.leftViewMode = .always
        passwordInput2.layer.borderWidth = 1.0
        passwordInput2.layer.borderColor = UIColor.kinPrimaryBlue.cgColor
        passwordInput2.layer.cornerRadius = 20.0
        confirmTick.layer.borderWidth = 1.0
        confirmTick.layer.borderColor = UIColor.kinBlueGreyTwo.cgColor
        confirmTick.layer.cornerRadius = 2.0
        doneButton.layer.cornerRadius = 25.0
        doneButton.backgroundColor = UIColor.kinPrimaryBlue
        titleLabel.attributedText = viewModel.passwordTitle
        passwordInfo.attributedText = viewModel.passwordInfo
        confirmLabel.attributedText = viewModel.confirmInfo
        kbObservers.append(NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: nil) { [weak self] note in
            if let height = (note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height,
                let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
                DispatchQueue.main.async {
                    self?.bottomSpace.constant = height
                    UIView.animate(withDuration: duration) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        })
        
        kbObservers.append(NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: nil) { [weak self] note in
            if let duration = note.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double {
                DispatchQueue.main.async {
                    self?.bottomSpace.constant = 0.0
                    UIView.animate(withDuration: duration) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        })
    }
    
    @IBAction func passwordEntryChanged(_ sender: Any) {
        // 
    }
    
    deinit {
        kbObservers.forEach { obs in
            NotificationCenter.default.removeObserver(obs)
        }
        kbObservers.removeAll()
    }

}
