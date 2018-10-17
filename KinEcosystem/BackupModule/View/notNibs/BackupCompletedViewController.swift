//
//  BackupCompletedViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class BackupCompletedViewController: BackupExplanationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "kinecosystem_backup_completed_title".localized()
        descriptionLabel.text = "kinecosystem_backup_completed_description".localized()
        bottomContainerView.isHidden = false
        bottomTitleLabel.text = "kinecosystem_backup_completed_sub_title".localized()
        bottomDescriptionLabel.text = "kinecosystem_backup_completed_sub_description".localized()
    }
}
