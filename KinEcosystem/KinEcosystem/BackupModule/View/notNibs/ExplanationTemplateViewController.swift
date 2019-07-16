//
//  ExplanationTemplateViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 17/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinUtil

class ExplanationTemplateViewController: BRViewController, Themed {
    let themeLinkBag = LinkBag()
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var reminderContainerView: UIView!
    @IBOutlet weak var reminderTitleLabel: UILabel!
    @IBOutlet weak var reminderDescriptionLabel: UILabel!
    @IBOutlet weak var continueButton: KinButton!
    @IBOutlet weak var topSpace: NSLayoutConstraint!
    @IBOutlet var stackViewTopConstraint:NSLayoutConstraint!
    init() {
        super.init(nibName: "ExplanationTemplateViewController", bundle: KinBundle.ecosystem.rawValue)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    private func commonInit() {
        
        loadViewIfNeeded()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        if #available(iOS 11, *) {
            topSpace.constant = 0.0
            view.layoutIfNeeded()
        }
        
        if UIScreen.main.bounds.height <= 568.0 { //Match small screen devices
            stackViewTopConstraint.constant = 0
        }
    }

    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.viewControllerColor
    }
}
