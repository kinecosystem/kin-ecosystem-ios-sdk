//
//  RestoreViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

protocol RestoreDelegate: NSObjectProtocol {
    // func: try restoring with the pass and qr
}

@available(iOS 9.0, *)
class RestoreViewController: BRViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var passwordInput: PasswordEntryField!
    @IBOutlet weak var doneButton: RoundButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    
    private let passwordInstructions = "kinecosystem_restore_instructions".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let passwordPlaceholder = "kinecosystem_enter_password".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private var kbObservers = [NSObjectProtocol]()

    init() {
        super.init(nibName: "RestoreViewController", bundle: Bundle.ecosystem)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadViewIfNeeded()
        title = "Restore Previous Wallet".localized()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordInput.attributedPlaceholder = passwordPlaceholder
        passwordInput.isSecureTextEntry = true
        instructionsLabel.attributedText = passwordInstructions
        doneButton.setTitleColor(UIColor.kinWhite, for: .normal)
        doneButton.isEnabled = false
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
        passwordInput.becomeFirstResponder()
    }
    
    @IBAction func passwordInputChanges(_ sender: PasswordEntryField) {
        doneButton.isEnabled = sender.hasText
    }
    
    @IBAction func doneButtonTapped(_ sender: RoundButton) {
        sender.transitionToConfirmed()
    }
    
    deinit {
        kbObservers.forEach { obs in
            NotificationCenter.default.removeObserver(obs)
        }
        kbObservers.removeAll()
    }
    
}
