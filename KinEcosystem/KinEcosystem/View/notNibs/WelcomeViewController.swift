//
//  WelcomeViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 07/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinCoreSDK

class WelcomeViewController: KinViewController {

    var core: Core!
    var transition: SplashTransition?
    let linkBag = LinkBag()

    @IBOutlet weak var diggingText: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var diggingTextHeight: NSLayoutConstraint!
    @IBOutlet var getStartedTrailing: NSLayoutConstraint!
    @IBOutlet var getStartedLeading: NSLayoutConstraint!
    @IBOutlet var getStartedWidth: NSLayoutConstraint!
    @IBOutlet weak var diamondsLoader: DiamondsLoaderView!
    @IBOutlet weak var closeButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        closeButton.isHidden = true
        getStartedButton.adjustsImageWhenDisabled = false
        setupTextLabels()
        Kin.track { try WelcomeScreenPageViewed() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func getStartedTapped(_ sender: Any) {
        Kin.track { try WelcomeScreenButtonTapped() }
        getStartedButton.isEnabled = false
        closeButton.isHidden = true
        shrinkButton()
            .then(on: .main) { () -> Promise<Void> in
                self.diamondsLoader.startAnimating()
                return Kin.shared.attempOnboard(self.core)
            }.then(on: .main) { [weak self] in
                self?.diamondsLoader.stopAnimating() {
                    self?.presentMarketplace()
                }
            }
            .error { [weak self] error in
                self?.closeButton.isHidden = false
                logError("onboarding failed: error: \(KinEcosystemError.transform(error))")
                self?.expandButtonForRetry()
        }
    }

    func setupTextLabels() {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 22
        style.alignment = .center
        diggingText.numberOfLines = 5
        diggingText.adjustsFontSizeToFitWidth = true
        diggingText.minimumScaleFactor = 0.5
        diggingText.allowsDefaultTighteningForTruncation = true
        let digg = "kinecosystem_welcome_kin_info".localized()
        let mutableDigging = NSMutableAttributedString(attributedString:
            digg.attributed(14.0, weight: .regular, color: .white))
        mutableDigging.addAttributes([ .paragraphStyle : style],
                                     range: NSRange(location: 0, length: digg.count))
        
        let context = NSStringDrawingContext()
        context.minimumScaleFactor = 0.5
        diggingText.attributedText = mutableDigging
        diggingTextHeight.constant = mutableDigging.boundingRect(with: CGSize(width: diggingText.bounds.width,
                                                                              height: .greatestFiniteMagnitude),
                                                                 options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                 context: context).height
        diggingText.layoutIfNeeded()
        getStartedButton.setAttributedTitle("kinecosystem_let_s_get_started".localized().attributed(16.0, weight: .regular, color: .kinDeepSkyBlue), for: .normal)
        getStartedButton.titleLabel?.isUserInteractionEnabled = false
    }

    func shrinkButton() -> Promise<Void> {
        let p = Promise<Void>()
        UIView.animate(withDuration: 0.1, animations: {
            self.getStartedButton.titleLabel?.alpha = 0.0
        }) { _ in
            
            self.getStartedLeading.isActive = false
            self.getStartedTrailing.isActive = false
            self.getStartedWidth.isActive = true
            
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.5, options: [], animations: {
                self.getStartedButton.layoutIfNeeded()
            }) { _ in
                p.signal(())
            }
        }
       return p
    }
    
    func expandButtonForRetry() {
        
        diamondsLoader.stopAnimating() {
        
            self.getStartedWidth.isActive = false
            self.getStartedLeading.isActive = true
            self.getStartedTrailing.isActive = true
            
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.5, options: [], animations: {
                self.getStartedButton.layoutIfNeeded()
            }) { _ in
                self.getStartedButton.setAttributedTitle("kinecosystem_retry".localized().attributed(16.0, weight: .regular, color: .kinDeepSkyBlue), for: .normal)
                UIView.animate(withDuration: 0.1, animations: {
                    self.getStartedButton.titleLabel?.alpha = 1.0
                }) { _ in
                    self.getStartedButton.isEnabled = true
                }
            }
        }
    }

    func presentMarketplace() {
        transition = SplashTransition(animatedView: getStartedButton)
        let mpViewController = MarketplaceViewController(nibName: "MarketplaceViewController", bundle: KinBundle.ecosystem.rawValue)
        mpViewController.core = core
        let navigationController = KinNavigationViewController(nibName: "KinNavigationViewController",
                                                                        bundle: KinBundle.ecosystem.rawValue,
                                                                        rootViewController: mpViewController,
                                                                        core: core)
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = transition
        present(navigationController, animated: true)
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        Kin.shared.closeMarketPlace()
    }
}
