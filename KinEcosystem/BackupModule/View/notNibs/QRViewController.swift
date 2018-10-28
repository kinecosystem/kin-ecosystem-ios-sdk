//
//  QRViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 18/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import MessageUI

@available(iOS 9.0, *)
class QRViewController: BRViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var reminderImageView: UIImageView!
    @IBOutlet weak var reminderTitleLabel: UILabel!
    @IBOutlet weak var reminderDescriptionLabel: UILabel!
    @IBOutlet weak var emailButton: RoundButton!
    @IBOutlet weak var continueContainerView: UIView!
    @IBOutlet weak var continueButton: RoundButton!
    
    private let qrString: String
    
    init(qrString: String) {
        self.qrString = qrString
        super.init(nibName: "QRViewController", bundle: Bundle.ecosystem)
        loadViewIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "kinecosystem_backup_qr_title".localized()
        titleLabel.textColor = .kinPrimaryBlue
        descriptionLabel.text = "kinecosystem_backup_qr_description".localized()
        descriptionLabel.textColor = .kinBlueGreyTwo
        qrImageView.image = QR.generateImage(from: qrString, for: qrImageView.bounds.size)
        reminderImageView.tintColor = .kinWarning
        reminderTitleLabel.text = "kinecosystem_backup_reminder_title".localized()
        reminderTitleLabel.textColor = .kinWarning
        reminderDescriptionLabel.text = "kinecosystem_backup_reminder_description".localized()
        reminderDescriptionLabel.textColor = .kinWarning
        emailButton.setTitle("kinecosystem_backup_qr_email".localized(), for: .normal)
        emailButton.setTitleColor(.white, for: .normal)
        emailButton.backgroundColor = .kinPrimaryBlue
        emailButton.addTarget(self, action: #selector(presentEmailViewController), for: .touchUpInside)
        continueButton.setTitle("kinecosystem_backup_qr_continue".localized(), for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .kinSuccess
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidTakeScreenshot), name: .UIApplicationUserDidTakeScreenshot, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationDidTakeScreenshot() {
        if isViewLoaded && view.window != nil && isContinueButtonHidden {
            showContinueButton()
        }
    }
    
    private func showContinueButton() {
        if view.window == nil {
            continueContainerView.isHidden = false
        }
        else {
            let delay = 0.2 // Create a delay to prevent a UI jump from the screenshot flash animation
            UIView.animate(withDuration: 0.3, delay: delay, options: UIViewAnimationOptions(rawValue: 0), animations: {
                self.continueContainerView.isHidden = false
            })
        }
    }
    
    private var isContinueButtonHidden: Bool {
        return continueContainerView.isHidden
    }
}

// MARK: - Email

@available(iOS 9.0, *)
extension QRViewController {
    private enum EmailError: Error {
        case noClient
        case critical
        
        var title: String {
            // TODO: get correct copy
            switch self {
            case .noClient:
                return "No email client"
            case .critical:
                return "Something went wrong"
            }
        }
        
        var message: String {
            // TODO: get correct copy
            switch self {
            case .noClient:
                return "You need to set up an email client first in the settings app."
            case .critical:
                return "Try again."
            }
        }
    }
    
    @objc private func presentEmailViewController() {
        guard MFMailComposeViewController.canSendMail() else {
            presentEmailErrorAlert(.noClient)
            return
        }
        
        guard let qrImage = QR.generateImage(from: qrString), let data = UIImagePNGRepresentation(qrImage) else {
            presentEmailErrorAlert(.critical)
            return
        }
        
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = self
//        mailViewController.setToRecipients([""])
        mailViewController.setSubject("Kin Backup QR Code") // TODO: get correct copy
        mailViewController.addAttachmentData(data, mimeType: "image/png", fileName: "qr.png")
        present(mailViewController, animated: true)
    }
    
    private func presentEmailErrorAlert(_ error: EmailError) {
        let alertController = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "kinecosystem_ok".localized(), style: .cancel))
        present(alertController, animated: true)
    }
}

@available(iOS 9.0, *)
extension QRViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        showContinueButton()
    }
}