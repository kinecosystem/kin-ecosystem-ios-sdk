//
//  BackupIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinMigrationModule

class BackupIntroViewController: ExplanationTemplateViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        continueButton.setTitle("kinecosystem_backup_intro_continue".localized(), for: .normal)
        Kin.track { try BackupWelcomePageViewed() }
        setupTheming()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        if parent == nil {
            Kin.track { try BackupWelcomePageBackButtonTapped() }
        }
    }

    override func applyTheme(_ theme: Theme) {
        super.applyTheme(theme)

        imageView.image = UIImage(named: "safeIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        titleLabel.attributedText = "kinecosystem_backup_intro_title".localized().styled(as: theme.title20)
        descriptionLabel.attributedText = "kinecosystem_backup_intro_description".localized().styled(as: theme.subtitle14)

        reminderContainerView.isHidden = true
    }
}
