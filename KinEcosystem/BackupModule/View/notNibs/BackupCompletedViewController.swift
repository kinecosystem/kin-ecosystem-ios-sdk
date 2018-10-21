//
//  BackupCompletedViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class BackupCompletedViewController: BackupExplanationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = UIImage(named: "safeIcon", in: Bundle.ecosystem, compatibleWith: nil)
        titleLabel.text = "kinecosystem_backup_completed_title".localized()
        descriptionLabel.text = "kinecosystem_backup_completed_description".localized()
        bottomContainerView.isHidden = false
        reminderTitleLabel.text = "kinecosystem_backup_reminder_title".localized()
        reminderDescriptionLabel.text = "kinecosystem_backup_reminder_description".localized()
    }
}
