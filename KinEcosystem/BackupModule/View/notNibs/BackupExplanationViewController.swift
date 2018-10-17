//
//  BackupExplanationViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

public class BackupExplanationViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: RoundButton!
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var bottomTitleLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .kinDeepSkyBlue
    }
}
