//
//  RestoreViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 29/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
protocol RestoreViewControllerDelegate: NSObjectProtocol {
    func restoreViewControllerDidImport(_ viewController: RestoreViewController, completion:@escaping (RestoreViewController.ImportResult) -> ())
    func restoreViewControllerDidComplete(_ viewController: RestoreViewController)
}

@available(iOS 9.0, *)
class RestoreViewController: BRViewController {
    weak var delegate: RestoreViewControllerDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var passwordInput: PasswordEntryField!
    @IBOutlet weak var doneButton: RoundButton!
    @IBOutlet weak var bottomSpace: NSLayoutConstraint!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    
    private let passwordInstructions = "kinecosystem_restore_instructions".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
    private let passwordPlaceholder = "kinecosystem_enter_password".localized().attributed(12.0, weight: .regular, color: UIColor.kinBlueGreyTwo)
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
        title = "Restore Previous Wallet".localized() // TODO: 
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
        passwordInput.attributedPlaceholder = passwordPlaceholder
        passwordInput.isSecureTextEntry = true
        instructionsLabel.attributedText = passwordInstructions
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
        doneButton.isEnabled = sender.hasText
    }
    
    @IBAction func doneButtonTapped(_ sender: RoundButton) {
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
            guard let this = self else {
                return
            }
            DispatchQueue.main.async {
                if result == .success {
                    
                    sender.transitionToConfirmed { () -> () in
                        this.delegate?.restoreViewControllerDidComplete(this)
                    }
                }
                else {
                    sender.isEnabled = true
                    this.navigationItem.hidesBackButton = false
                    this.presentErrorAlertController(result: result)
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
