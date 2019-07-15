//
//  BackupCompletedViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//
import UIKit
import KinUtil
class BackupCompletedViewController: ExplanationTemplateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Kin.track { try BackupCompletedPageViewed() }
        navigationItem.hidesBackButton = true
        imageView.image = UIImage(named: "safeIcon", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        continueButton.isHidden = true
    }
    override func applyTheme(_ theme: Theme) {
        super.applyTheme(theme)
        var attributedString = NSMutableAttributedString()
        attributedString.append("kinecosystem_backup_completed_title".localized().styled(as: theme.title20).applyingTextAlignment(.center))
        titleLabel.attributedText = attributedString
        attributedString = NSMutableAttributedString()
        attributedString.append("kinecosystem_backup_completed_description".localized().styled(as: theme.subtitle14))
        attributedString.append(NSAttributedString(string: "\n\n"))
        attributedString.append("kinecosystem_backup_reminder_description".localized().styled(as: theme.subtitle12).applyingTextColor(Color.KinNewUi.darkishPink))
        descriptionLabel.attributedText = attributedString
        descriptionHeight.constant = 500
    }
}
