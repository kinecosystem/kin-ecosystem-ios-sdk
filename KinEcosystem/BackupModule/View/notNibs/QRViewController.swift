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
        qrImageView.image = generateQRImage(from: qrString, for: qrImageView.bounds.size)
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
        if isViewLoaded && view.window != nil && continueButton.isHidden {
            showContinueButton()
        }
    }
    
    private func showContinueButton() {
        continueContainerView.isHidden = false
    }
}

// MARK: - QR

@available(iOS 9.0, *)
extension QRViewController {
    /**
     Create a QR image from a string.
     
     - Parameter string: The string used in the QR image.
     - Parameter size: The size of the `UIImageView` that will display the image.
     - Returns: A QR image.
     */
    private func generateQRImage(from string: String, for size: CGSize? = nil) -> UIImage? {
        let data = string.data(using: .isoLatin1)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let transform: CGAffineTransform
        
        if let size = size {
            let scaleX = size.width / outputImage.extent.width
            let scaleY = size.height / outputImage.extent.height
            transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        }
        else {
            transform = CGAffineTransform(scaleX: 10, y: 10)
        }
        
        return UIImage(ciImage: outputImage.transformed(by: transform))
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
        
        guard let qrImage = generateQRImage(from: qrString), let data = UIImagePNGRepresentation(qrImage) else {
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
        // TODO: get correct copy
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alertController, animated: true)
    }
}

@available(iOS 9.0, *)
extension QRViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        showContinueButton()
    }
}
