//
//  RestoreViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinUtil

@available(iOS 9.0, *)
protocol RestoreViewControllerDelegate: NSObjectProtocol {
    func restoreViewControllerDidImport(_ viewController: RestoreViewController, completion:@escaping (RestoreViewController.ImportResult) -> ())
    func restoreViewControllerDidComplete(_ viewController: RestoreViewController)
}

@available(iOS 9.0, *)
class RestoreViewController: BRViewController {
    let themeLinkBag = LinkBag()
    weak var delegate: RestoreViewControllerDelegate?
    var theme: Theme = .light

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var passwordInput: PasswordEntryField!
    @IBOutlet weak var doneButton: KinButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var topSpace: NSLayoutConstraint!

    private var kbObservers = [NSObjectProtocol]()
    
    var password: String? {
        return passwordInput.text
    }
    
    init() {
        super.init(nibName: "RestoreViewController", bundle: KinBundle.ecosystem.rawValue)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadViewIfNeeded()
        title = "kinecosystem_restore_intro_title".localized()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            Kin.track { try RestorePasswordEntryBackButtonTapped() }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Kin.track { try RestorePasswordEntryPageViewed() }

        passwordInput.isSecureTextEntry = true
        doneButton.setTitleColor(UIColor.kinWhite, for: .normal)
        doneButton.isEnabled = false
        kbObservers.append(NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { [weak self] note in
            if let height = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height,
                let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                DispatchQueue.main.async {
                    self?.bottomSpace.constant = height
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

        passwordInput.becomeFirstResponder()
    }
    
    @IBAction func passwordInputChanges(_ sender: PasswordEntryField) {
        if sender.entryState == .invalid {
            sender.entryState = .idle
        }
        doneButton.isEnabled = sender.hasText
    }
    
    @IBAction func doneButtonTapped(_ sender: KinButton) {
        guard !navigationItem.hidesBackButton else {
            // Button in mid transition
            return
        }

        Kin.track { try RestorePasswordDoneButtonTapped() }

        guard let delegate = delegate else {
            return
        }

        sender.isEnabled = false
        navigationItem.hidesBackButton = true

        delegate.restoreViewControllerDidImport(self) { [weak self] result in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                guard result == .success else {
                    sender.isEnabled = true
                    self.navigationItem.hidesBackButton = false
                    self.passwordInput.entryState = .invalid
                    self.presentErrorAlertController(result: result)
                    return
                }

                self.instructionsLabel.attributedText = "kinecosystem_restore_done"
                    .localized()
                    .styled(as: self.theme.subtitle12)
                sender.transitionToConfirmed {
                    self.delegate?.restoreViewControllerDidComplete(self)
                }
            }
        }
    }
    
    deinit {
        kbObservers.forEach { obs in
            NotificationCenter.default.removeObserver(obs)
        }
        kbObservers.removeAll()
    }
}

@available(iOS 9.0, *)
extension RestoreViewController {
    enum ImportResult {
        case success
        case wrongPassword
        case invalidImage
        case internalIssue
        
        var errorDescription: String? {
            // TODO: get correct copy
            switch self {
            case .success:
                return nil
            case .wrongPassword:
                return "The password is not correct."
            case .invalidImage:
                return "The QR image could not be identified."
            case .internalIssue:
                return "Something went wrong. Try again."
            }
        }
    }

    private func presentErrorAlertController(result: ImportResult) {
        // TODO: get correct copy
        
        let alertController = UIAlertController(title: "Try again", message: result.errorDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "kinecosystem_ok".localized(), style: .cancel))
        present(alertController, animated: true)
    }
}

extension RestoreViewController: Themed {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        instructionsLabel.attributedText = "kinecosystem_restore_instructions"
            .localized()
            .styled(as: theme.subtitle12)
        passwordInput.attributedPlaceholder = "kinecosystem_enter_password"
            .localized()
            .styled(as: theme.lightSubtitle14)
    }
}
