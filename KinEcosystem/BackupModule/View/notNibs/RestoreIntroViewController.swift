//
//  RestoreIntroViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class RestoreIntroViewController: ExplanationTemplateViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = UIImage(named: "whiteQrCode", in: Bundle.ecosystem, compatibleWith: nil)
        titleLabel.text = "kinecosystem_restore_intro_title".localized()
        descriptionLabel.text = "kinecosystem_restore_intro_description".localized()
        continueButton.setTitle("kinecosystem_restore_intro_continue".localized(), for: .normal)
        reminderContainerView.isHidden = true
    }
}

