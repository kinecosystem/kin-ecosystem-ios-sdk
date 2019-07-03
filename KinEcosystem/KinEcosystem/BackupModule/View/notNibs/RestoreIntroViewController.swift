//
//  RestoreIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
protocol RestoreIntroViewControllerDelegate: NSObjectProtocol {
    func restoreIntroViewControllerDidComplete(_ viewController: RestoreIntroViewController)
}

@available(iOS 9.0, *)
class RestoreIntroViewController: ExplanationTemplateViewController {
    weak var delegate: RestoreIntroViewControllerDelegate?
    private var canContinue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Kin.track { try RestoreUploadQrCodePageViewed() }
        imageView.image = UIImage(named: "whiteQrCode", in: Bundle.ecosystem, compatibleWith: nil)
        titleLabel.text = "kinecosystem_restore_intro_title".localized()
        descriptionLabel.text = "kinecosystem_restore_intro_description".localized()
        reminderContainerView.isHidden = true
        continueButton.setTitle("kinecosystem_restore_intro_continue".localized(), for: .normal)
        continueButton.addTarget(self, action: #selector(continueAction), for: .touchUpInside)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            Kin.track { try RestoreUploadQrCodeBackButtonTapped() }
        }
    }
    
    @objc private func continueAction() {
        Kin.track { try RestoreUploadQrCodeButtonTapped() }
        if canContinue {
            delegate?.restoreIntroViewControllerDidComplete(self)
        }
        else {
            presentAlertController()
        }
    }
    
    @objc private func presentAlertController() {
        let title = "kinecosystem_restore_intro_alert_title".localized()
        let message = "kinecosystem_restore_intro_alert_message".localized()
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let continueAction = UIAlertAction(title: "kinecosystem_ok".localized(), style: .default) { _ in
            Kin.track { try RestoreAreYouSureOkButtonTapped() }
            self.canContinue = true
            self.delegate?.restoreIntroViewControllerDidComplete(self)
        }
        alertController.addAction(UIAlertAction(title: "kinecosystem_cancel".localized(), style: .cancel) { _ in
            Kin.track { try RestoreAreYouSureCancelButtonTapped() }
        })
        alertController.addAction(continueAction)
        alertController.preferredAction = continueAction
        present(alertController, animated: true)
    }
}

