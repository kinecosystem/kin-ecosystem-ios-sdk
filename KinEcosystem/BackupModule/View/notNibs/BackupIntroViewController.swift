//
//  BackupIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 16/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class BackupIntroViewController: BackupExplanationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "kinecosystem_backup_intro_title".localized()
        descriptionLabel.text = "kinecosystem_backup_intro_description".localized()
        continueButton.setTitle("kinecosystem_backup_intro_continue".localized(), for: .normal)
        continueButton.isHidden = false
    }
}
