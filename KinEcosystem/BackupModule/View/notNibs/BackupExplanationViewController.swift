//
//  BackupExplanationViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
public class BackupExplanationViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var continueButton: RoundButton!
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var bottomTitleLabel: UILabel!
    @IBOutlet weak var bottomDescriptionLabel: UILabel!

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
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .kinPrimaryBlue
        continueButton.setTitleColor(.kinPrimaryBlue, for: .normal)
    }
}
