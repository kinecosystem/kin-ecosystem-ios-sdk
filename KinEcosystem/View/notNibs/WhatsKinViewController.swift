//
//  WhatsKinViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/05/2019.
//

import UIKit
import KinMigrationModule

protocol WhatsKinViewControllerDelegate: class {
    func whatsKinViewControllerDidTapCloseButton()
    func whatsKinViewControllerDidTapLetsGoButton()
}

class WhatsKinViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var button: KinButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var dotsActivityIndicator: KinDotsActivityIndicator!
    
    weak var flowDelegate: WhatsKinViewControllerDelegate?
    
    let themeLinkBag = LinkBag()
    
    init() {
        super.init(nibName: "WhatsKinViewController", bundle: KinBundle.ecosystem.rawValue)
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
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "closeBtn",
                                                                          in: KinBundle.ecosystem.rawValue,
                                                                          compatibleWith: nil),
                                                           style: .plain,
                                                           target: nil,
                                                           action: nil)
        navigationItem.leftBarButtonItem?.actionClosure = { [weak self] in
            self?.flowDelegate?.whatsKinViewControllerDidTapCloseButton()
        }
        button.actionClosure =  { [weak self] in
            self?.flowDelegate?.whatsKinViewControllerDidTapLetsGoButton()
        }
        setupTheming()
    }
    
    func setLoaderHidden(_ hidden: Bool) {
        button.isHidden = !hidden
        dotsActivityIndicator.isHidden = hidden
        if hidden {
            dotsActivityIndicator.stopAnimating()
        } else {
            dotsActivityIndicator.startAnimating()
        }
    }

}

extension WhatsKinViewController: Themed {
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.viewControllerColor
        button.type = .purple
        button.setAttributedTitle("lets_go".localized().styled(as: theme.buttonTitle), for: [])
        titleLabel.attributedText = "whats_kin".localized().styled(as: theme.title20Condensed)
        infoLabel.attributedText = "kin_is_a_digital_currency".localized().styled(as: theme.subtitle14)
        imageView.image = UIImage(named: "hifiveLight", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        logoView.image = UIImage(named: "kinLogoPurple", in: KinBundle.ecosystem.rawValue, compatibleWith: nil)
        navigationItem.leftBarButtonItem?.tintColor = theme.closeButtonTint
        dotsActivityIndicator.tintColor = theme.dotsLoaderTint
    }
}
