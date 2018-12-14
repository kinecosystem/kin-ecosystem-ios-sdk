//
//  BackupIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class BackupIntroViewController: ExplanationTemplateViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Kin.track { try BackupWelcomePageViewed() }
        imageView.image = UIImage(named: "safeIcon", in: Bundle.ecosystem, compatibleWith: nil)
        titleLabel.text = "kinecosystem_backup_intro_title".localized()
        descriptionLabel.text = "kinecosystem_backup_intro_description".localized()
        continueButton.setTitle("kinecosystem_backup_intro_continue".localized(), for: .normal)
        reminderContainerView.isHidden = true
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        if parent == nil {
            Kin.track { try BackupWelcomePageBackButtonTapped() }
        }
    }
}
