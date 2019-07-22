//
//  PasswordEntryViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule

@available(iOS 9.0, *)
protocol PasswordEntryDelegate: NSObjectProtocol {
    func validatePasswordConformance(_ password: String) -> Bool
    func passwordEntryViewControllerDidComplete(_ viewController: PasswordEntryViewController)
}

private enum PasswordsState {
    case clean
    case firstInvalid
    case firstValid
    case mismatch
    case validAndMatch
}

@available(iOS 9.0, *)
class PasswordEntryViewController: BRViewController {
    let themeLinkBag = LinkBag()
    var theme: Theme?

    private var passwordState: PasswordsState = .clean {
        didSet {
            updatePasswordState()
        }
    }

    @IBOutlet weak var passwordInfo: UILabel!

    @IBOutlet weak var passwordInput1: PasswordEntryField!
    @IBOutlet weak var passwordInput2: PasswordEntryField!
    @IBOutlet weak var confirmLabel: UILabel! {
        didSet {
            confirmLabel.textAlignment = .left
        }
    }

    @IBOutlet weak var confirmTick: UIView!
    @IBOutlet weak var doneButton: KinButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var tickStack: UIStackView!
    @IBOutlet weak var tickImageView: UIImageView!
    @IBOutlet weak var topSpace: NSLayoutConstraint!

    weak var delegate: PasswordEntryDelegate?

    private var kbObservers = [NSObjectProtocol]()
    private var tickMarked = false
    fileprivate let passwordConditions = "kinecosystem_password_conditions".localized()

    var password: String? {
        return passwordInput1.text
    }

    deinit {
        kbObservers.forEach { obs in
            NotificationCenter.default.removeObserver(obs)
        }
        kbObservers.removeAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        confirmTick.layer.borderWidth = 1.0
        confirmTick.layer.cornerRadius = 2.0
        doneButton.isEnabled = false
        tickImageView.isHidden = true
        setupTheming()
        Kin.track { try BackupCreatePasswordPageViewed() }
        kbObservers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] note in
            if let height = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height,
                let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                DispatchQueue.main.async {
                    self?.bottomSpace.constant = height + 10
                    UIView.animate(withDuration: duration) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        })
        
        kbObservers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { [weak self] note in
            if let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                DispatchQueue.main.async {
                    self?.bottomSpace.constant = 0.0
                    UIView.animate(withDuration: duration) {
                        self?.view.layoutIfNeeded()
                    }
                }
            }
        })
        if #available(iOS 11, *) {
            topSpace.constant = 0.0
            view.layoutIfNeeded()
        }

        passwordInput1.inputAccessoryView?.isHidden = true
        passwordInput1.inputAccessoryView?.isUserInteractionEnabled = false
        passwordInput2.inputAccessoryView?.isHidden = true
        passwordInput2.inputAccessoryView?.isUserInteractionEnabled = false
        if #available(iOS 12, *) {
            passwordInput1.textContentType = .oneTimeCode
            passwordInput2.textContentType = .oneTimeCode
        } else if #available(iOS 12, *) {
            passwordInput1.textContentType = .init(rawValue: "")
            passwordInput2.textContentType = .init(rawValue: "")
        }
        passwordInput1.becomeFirstResponder()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back",
//                                                                          in: KinBundle.ecosystem.rawValue,
//                                                                          compatibleWith: nil),
//                                                           style: .plain) { [weak self] in self?.dismiss(animated: true, completion:nil) }
    }
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            Kin.track { try BackupCreatePasswordBackButtonTapped() }
        }
    }

    @IBAction func passwordEntryChanged(_ sender: UITextField) {
        guard let delegate = delegate else {
            return
        }

        guard let input1Text = passwordInput1.text, !input1Text.isEmpty else {
            passwordState = .clean
            return
        }

        updateDoneButton()

        guard delegate.validatePasswordConformance(input1Text) else {
            passwordState = .firstInvalid
            return
        }

        guard !(passwordInput2.text ?? "").isEmpty else {
            passwordState = .firstValid
            return
        }

        guard passwordInput2.text == input1Text else {
            passwordState = .mismatch
            return
        }

        passwordState = .validAndMatch
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        Kin.track { try BackupCreatePasswordNextButtonTapped() }
        guard
            let text = passwordInput1.text,
            let delegate = delegate,
            passwordInput1.hasText,
            passwordInput2.hasText,
            passwordInput1.text == passwordInput2.text,
            delegate.validatePasswordConformance(text) else {
            return // shouldn't really happen, here for documenting
        }

        delegate.passwordEntryViewControllerDidComplete(self)
    }

    @IBAction func tickSelected(_ sender: Any) {
        tickMarked = !tickMarked
        tickImageView.isHidden = !tickMarked
        confirmTick.layer.borderWidth = tickMarked ? 0 : 1.0
        updateDoneButton()
    }

    func updateDoneButton() {
        guard let delegate = delegate else { fatalError() }

        doneButton.isEnabled = delegate.validatePasswordConformance(passwordInput1.text ?? "")
            && passwordInput2.text == passwordInput1.text
            && tickMarked
    }

    fileprivate func updatePasswordState() {
        let theme = self.theme ?? .light
        let attributedString: NSAttributedString = {
            switch passwordState {
            case .clean, .firstValid, .validAndMatch:
                return "kinecosystem_password_instructions".localized().styled(as: theme.subtitle12) + passwordConditions.localized().styled(as: .lightSubtitle12AnyTheme)
            case .firstInvalid:
                return "kinecosystem_password_invalid_warning".localized().styled(as: .invalidPassword) + passwordConditions.localized().styled(as: theme.subtitle12)
            case .mismatch:
                return "kinecosystem_password_mismatch".localized().styled(as: .invalidPassword) + passwordConditions.localized().styled(as: theme.subtitle12)
            }
        }()

        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 6

        mutableAttributedString.addAttributes([.paragraphStyle : paragraphStyle],
                                              range: NSRange.init(location: 0, length: mutableAttributedString.string.count))
        passwordInfo.attributedText = mutableAttributedString

        switch passwordState {
        case .clean:
            passwordInput1.entryState = .idle
            passwordInput2.entryState = .idle
        case .firstInvalid:
            passwordInput1.entryState = .invalid
            passwordInput2.entryState = .idle
        case .firstValid:
            passwordInput1.entryState = .valid
            passwordInput2.entryState = .idle
        case .mismatch:
            passwordInput1.entryState = .invalid
            passwordInput2.entryState = .invalid
        case .validAndMatch:
            passwordInput1.entryState = .valid
            passwordInput2.entryState = .valid
        }
    }
}

extension PasswordEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordInput1 {
            passwordInput2.becomeFirstResponder()
        }

        if textField == passwordInput2 {
            view.endEditing(true)
        }

        return false
    }
}
extension PasswordEntryViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme

        updatePasswordState()
        passwordInput1.attributedPlaceholder = "kinecosystem_password".localized().styled(as: .lightSubtitle14AnyTheme)
        passwordInput2.attributedPlaceholder = "kinecosystem_confirm_password".localized().styled(as: .lightSubtitle14AnyTheme)

        confirmLabel.attributedText = "kinecosystem_password_confirmation"
            .localized()
            .styled(as: theme.subtitle12)
            .applyingTextAlignment(.left)
        confirmTick.layer.borderColor = theme.mainTintColor.cgColor
    }
}
