//
//  InsufficientFundsViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/04/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class InsufficientFundsViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.attributedText = "kinecosystem_you_dont_have_enough_kin".localized().attributed(22.0, weight: .regular, color: .kinBlueGrey)
        descriptionLabel.attributedText = "Go to the earn section to earn more Kin".attributed(14.0, weight: .regular, color: .kinBlueGreyTwo)
        imageView.image = UIImage.bundleImage("kinlogo")
        goButton.setAttributedTitle("Earn Offers".attributed(16.0, weight: .regular, color: .kinWhite), for: .normal)
        goButton.backgroundColor = .kinDeepSkyBlue
        goButton.adjustsImageWhenDisabled = false
        Kin.track { try NotEnoughKinPageViewed() }
    }

    @IBAction func goTapped(_ sender: Any) {
        close()
    }
    @IBAction func closeTapped(_ sender: Any) {
        close()
    }
    
    func close() {
        let transition = SheetTransition()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transition
        self.dismiss(animated: true)
    }
}

