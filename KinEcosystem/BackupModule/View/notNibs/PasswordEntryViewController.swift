//
//  PasswordEntryViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
protocol PasswordEntryDelegate: NSObjectProtocol {
    func validatePasswordConformance(_ password: String) -> Bool
    func passwordEntryViewControllerDidComplete(_ viewController: PasswordEntryViewController)
}

private class PEDoneButton: UIButton {
    override var isEnabled: Bool {
        didSet {
            self.backgroundColor = isEnabled ? UIColor.kinPrimaryBlue : UIColor.kinLightBlueGrey
        }
    }
}

@available(iOS 9.0, *)
class PasswordEntryViewController: BRViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var passwordInfo: UILabel!
    @IBOutlet weak var passwordInput1: PasswordEntryField!
    @IBOutlet weak var passwordInput2: PasswordEntryField!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmTick: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    
    weak var delegate: PasswordEntryDelegate?
    
    private var kbObservers = [NSObjectProtocol]()
    private var tickMarked = false
    private let passwordTitle = "kinecosystem_create_password".localized().attributed(20.0, weight: .light, color: UIColor.kinPrimaryBlue)
    private let passwordInstructions = "kinecosystem_password_instructions".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let confirmInfo = "kinecosystem_password_confirmation".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let passwordInvalidWarning = "kinecosystem_password_invalid_warning".localized().attributed(12.0, weight: .regular, color: UIColor.kinWarning)
    private let passwordMismatch = "kinecosystem_password_mismatch".localized().attributed(12.0, weight: .regular, color: UIColor.kinWarning)
    private let passwordInvalidInfo = "kinecosystem_password_invalid_info".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let passwordPlaceholder = "kinecosystem_password".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let passwordConfirmPlaceholder = "kinecosystem_confirm_password".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    
    var password: String? {
        return passwordInput1.text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmTick.layer.borderWidth = 1.0
        confirmTick.layer.borderColor = UIColor.kinBlueGreyTwo.cgColor
        confirmTick.layer.cornerRadius = 2.0
        doneButton.layer.cornerRadius = 25.0
        doneButton.setTitleColor(UIColor.kinWhite, for: .normal)
        doneButton.isEnabled = false
        titleLabel.attributedText = passwordTitle
        passwordInfo.attributedText = passwordInstructions
        confirmLabel.attributedText = confirmInfo
        passwordInput1.attributedPlaceholder = passwordPlaceholder
        passwordInput2.attributedPlaceholder = passwordConfirmPlaceholder
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
        passwordInput1.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = event?.allTouches?.first
        if (passwordInput1.isFirstResponder || passwordInput2.isFirstResponder) &&
            type(of: touch?.view) != UITextField.self {
            passwordInput1.resignFirstResponder()
            passwordInput2.resignFirstResponder()
        }
        super.touchesBegan(touches, with: event)
    }
    
    @IBAction func passwordEntryChanged(_ sender: UITextField) {
        updateDoneButton()
        if passwordInput1.hasText,
            let delegate = delegate,
            let text = passwordInput1.text,
            delegate.validatePasswordConformance(text) {
            passwordInput1.entryState = .valid
            if passwordInput2.text == text {
                passwordInput2.entryState = .valid
            } else {
                passwordInput2.entryState = .idle
            }
        } else {
            passwordInput1.entryState = .idle
        }
        passwordInfo.attributedText = passwordInstructions
    }
    
    
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        guard let text = passwordInput1.text, passwordInput1.hasText && passwordInput2.hasText else {
            return // shouldn't really happen, here for documenting
        }
        guard passwordInput1.text == passwordInput2.text else {
            alertPasswordsDontMatch()
            return
        }
        guard let delegate = delegate else { fatalError() }
        
        guard delegate.validatePasswordConformance(text) else {
            alertPasswordsConformance()
            return
        }
        delegate.passwordEntryViewControllerDidComplete(self)
    }
    
    @IBAction func tickSelected(_ sender: Any) {
        tickMarked = !tickMarked
        confirmTick.backgroundColor = tickMarked ? UIColor.kinLightBlueGrey : UIColor.kinWhite
        updateDoneButton()
    }
    
    func alertPasswordsDontMatch() {
        passwordInfo.attributedText = passwordMismatch
        passwordInput2.text = ""
        passwordInput1.becomeFirstResponder()
    }
    
    func alertPasswordsConformance() {
        passwordInfo.attributedText = passwordInvalidWarning + passwordInvalidInfo
    }
    
    func updateDoneButton() {
        doneButton.isEnabled = passwordInput1.hasText && passwordInput2.hasText && tickMarked
    }
    
    deinit {
        kbObservers.forEach { obs in
            NotificationCenter.default.removeObserver(obs)
        }
        kbObservers.removeAll()
    }

}
