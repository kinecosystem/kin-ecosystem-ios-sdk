//
//  QRViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 18/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class QRViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var reminderImageView: UIImageView!
    @IBOutlet weak var reminderTitleLabel: UILabel!
    @IBOutlet weak var reminderDescriptionLabel: UILabel!
    @IBOutlet weak var continueButton: RoundButton!
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        loadViewIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "kinecosystem_backup_qr_title".localized()
        titleLabel.textColor = .kinPrimaryBlue
        descriptionLabel.text = "kinecosystem_backup_qr_description".localized()
        descriptionLabel.textColor = .kinBlueGreyTwo
        reminderImageView.tintColor = .kinWarningRed
        reminderTitleLabel.text = "kinecosystem_backup_reminder_title".localized()
        reminderTitleLabel.textColor = .kinWarningRed
        reminderDescriptionLabel.text = "kinecosystem_backup_reminder_description".localized()
        reminderDescriptionLabel.textColor = .kinWarningRed
        continueButton.setTitle("kinecosystem_backup_qr_continue".localized(), for: .normal)
        continueButton.setTitleColor(.kinPrimaryBlue, for: .normal)
        continueButton.backgroundColor = .kinPrimaryBlue
        continueButton.setTitleColor(.white, for: .normal)
    }
}
