//
//  RestoreIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinUtil

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
        let arrowImage = UIImage(named: "uploadQrArrow", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        let arrowImageView = UIImageView(image: arrowImage)
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addSubview(arrowImageView)
        continueButton.centerYAnchor.constraint(equalTo: arrowImageView.centerYAnchor).isActive = true
        arrowImageView.trailingAnchor.constraint(equalTo: continueButton.trailingAnchor, constant: -24).isActive = true

        Kin.track { try RestoreUploadQrCodePageViewed() }
        imageView.image = UIImage(named: "restoreQR", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
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

        guard canContinue else {
            presentAlertController()
            return
        }

        delegate?.restoreIntroViewControllerDidComplete(self)
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

    override func applyTheme(_ theme: Theme) {
        super.applyTheme(theme)

        titleLabel.attributedText = "kinecosystem_restore_intro_title"
            .localized()
            .styled(as: theme.title20)
        descriptionLabel.attributedText = "kinecosystem_restore_intro_description"
            .localized()
            .styled(as: theme.subtitle14)
    }
}
