//
//  WelcomeViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 07/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinCoreSDK

@available(iOS 9.0, *)
class WelcomeViewController: KinViewController {

    var core: Core!
    var transition: SplashTransition?
    let linkBag = LinkBag()

    @IBOutlet weak var diggingText: UILabel!
    @IBOutlet weak var getStartedButton: UIButton!
    @IBOutlet weak var diggingTextHeight: NSLayoutConstraint!
    @IBOutlet weak var getStartedTrailing: NSLayoutConstraint!
    @IBOutlet weak var getStartedLeading: NSLayoutConstraint!
    @IBOutlet weak var diamondsLoader: DiamondsLoaderView!


    override func viewDidLoad() {
        super.viewDidLoad()
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
        shrinkButton()
            .then(on: .main) { [weak self] in
                self?.diamondsLoader.startAnimating()
                self?.acceptTosAndOnboard()
            .then(on: .main) {
                self?.diamondsLoader.stopAnimating() {
                    self?.presentMarketplace()
                }
            }
        }.error { error in

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
            self.getStartedButton.superview?.removeConstraints([self.getStartedLeading, self.getStartedTrailing])
            self.getStartedButton.widthAnchor.constraint(equalToConstant: 50.0).isActive = true
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.5, options: [], animations: {
                self.getStartedButton.layoutIfNeeded()
            }) { _ in
                p.signal(())
            }
        }
       return p
    }

    func acceptTosAndOnboard() -> Promise<Void> {
        let p = Promise<Void>()
        core.network.acceptTOS().then {
            if (self.core.blockchain.onboarded) {
                p.signal(())
            } else {
                self.core.blockchain.onboardEvent.on(next: { _ in
                    p.signal(())
                }).add(to: self.linkBag)
            }
            }.error { error in
                if case let EcosystemNetError.server(errString) = error {
                    logError("server returned bad answer: \(errString)")
                } else {
                    logError("onboarding wait failed - \(error)")
                }
        }
        return p
    }

    func presentMarketplace() {
        transition = SplashTransition(animatedView: getStartedButton)
        let mpViewController = MarketplaceViewController(nibName: "MarketplaceViewController", bundle: Bundle.ecosystem)
        mpViewController.core = core
        let navigationController = KinNavigationViewController(nibName: "KinNavigationViewController",
                                                                        bundle: Bundle.ecosystem,
                                                                        rootViewController: mpViewController)
        navigationController.core = core
        navigationController.modalPresentationStyle = .custom
        navigationController.transitioningDelegate = transition
        present(navigationController, animated: true)
    }

}
