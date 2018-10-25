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
    func passwordEntryViewControllerDidComplete()
}

class PEDoneButton: UIButton {
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
    
    var viewModel = PasswordEntryViewModel()
    var delegate: PasswordEntryDelegate?
    
    private var kbObservers = [NSObjectProtocol]()
    private var tickMarked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmTick.layer.borderWidth = 1.0
        confirmTick.layer.borderColor = UIColor.kinBlueGreyTwo.cgColor
        confirmTick.layer.cornerRadius = 2.0
        doneButton.layer.cornerRadius = 25.0
        doneButton.setTitleColor(UIColor.kinWhite, for: .normal)
        doneButton.isEnabled = false
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
        delegate.passwordEntryViewControllerDidComplete()
    }
    
    @IBAction func tickSelected(_ sender: Any) {
        tickMarked = !tickMarked
        confirmTick.backgroundColor = tickMarked ? UIColor.kinLightBlueGrey : UIColor.kinWhite
        updateDoneButton()
    }
    
    func alertPasswordsDontMatch() {
        
    }
    
    func alertPasswordsConformance() {
        
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
