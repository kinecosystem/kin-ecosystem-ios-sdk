//
//  KinFlow.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 02/06/2019.
//

import UIKit

protocol KinFlowControllerDelegate: NSObject {
    func flowControllerDidComplete(_ controller: KinFlowController)
    func flowControllerDidCancel(_ controller: KinFlowController)
}

class KinFlowController {
    
    weak var core: Core!
    weak var delegate: KinFlowControllerDelegate?
    let presentingViewController: UIViewController
    
    init(presentingViewController: UIViewController, core: Core) {
        self.presentingViewController = presentingViewController
        self.core = core
    }
    
    func start() {}
    
    func cancelFlow() {
        self.delegate?.flowControllerDidCancel(self)
    }
    
}

class EntrypointFlowController: KinFlowController {
    
    let navigationControllerWrapper: SheetNavigationControllerWrapper
    var startingExperience: EcosystemExperience = .marketplace
    var whatsKin: WhatsKinViewController?
    
    var didTapLetsGo: Bool {
        get {
            return UserDefaults.standard.bool(forKey: KinPreferenceKey.didTapLetsGo.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: KinPreferenceKey.didTapLetsGo.rawValue)
        }
    }
    
    override init(presentingViewController: UIViewController, core: Core) {
        navigationControllerWrapper = SheetNavigationControllerWrapper()
        navigationControllerWrapper.cover = .most
        super.init(presentingViewController: presentingViewController, core: core)
    }
    
    override func start() {
        if didTapLetsGo {
            if core.onboarded {
                showExperience()
            } else {
                showWhatsKin(onboarding: true)
            }
        } else {
            showWhatsKin(onboarding: false)
        }
        
    }
    
    func showWhatsKin(onboarding: Bool) {
        whatsKin = WhatsKinViewController()
        whatsKin!.delegate = self
        navigationControllerWrapper.pushViewController(whatsKin!, animated: false)
        presentingViewController.present(navigationControllerWrapper, animated: true)
        whatsKin!.setLoaderHidden(!onboarding)
        if onboarding {
            core.onboard().then(on: .main) { [weak self] in
                self?.showExperience()
            }.error { error in
                    
            }
        }
    }
    
    func showExperience() {
        
        let presented = presentingViewController.presentedViewController == navigationControllerWrapper
        let hasControllers = navigationControllerWrapper.wrappedNavigationController.viewControllers.count > 0
        let mpViewController = OffersViewController(core: core)
        mpViewController.delegate = self
        navigationControllerWrapper.pushViewController(mpViewController, animated: presented && hasControllers)
        if !presented {
            presentingViewController.present(navigationControllerWrapper, animated: true)
        }        
    }
    
    func cancelFlow(completion: @escaping () -> ()) {
        navigationControllerWrapper.dismiss(animated: true) {
            super.cancelFlow()
            completion()
        }
    }
    
    override func cancelFlow() {
        navigationControllerWrapper.dismiss(animated: true) {
            super.cancelFlow()
        }
    }
    
}

extension EntrypointFlowController: WhatsKinViewControllerDelegate {
    
    func whatsKinViewControllerDidTapCloseButton() {
        cancelFlow()
    }
    
    func whatsKinViewControllerDidTapLetsGoButton() {
        didTapLetsGo = true
        if core.onboarded {
            showExperience()
        } else {
            whatsKin?.setLoaderHidden(false)
            core.onboard().then(on: .main) { [weak self] in
                self?.showExperience()
            }.error { error in
                    
            }
        }
    }
}

extension EntrypointFlowController: OffersViewControllerDelegate {
    
    func offersViewControllerDidTapCloseButton() {
        cancelFlow()
    }
    
    func offersViewController(_ controller: OffersViewController, didTap offer: Offer) {
        
        guard offer.offerContentType != .external else {
            let nativeOffer = offer.nativeOffer
            let report: (NativeOffer) -> () = { nativeOffer in
                if nativeOffer.offerType == .spend {
                    Kin.track { try SpendOfferTapped(kinAmount: Double(nativeOffer.amount), offerID: nativeOffer.id, origin: .external) }
                } else {
                    Kin.track { try EarnOfferTapped(kinAmount: Double(nativeOffer.amount), offerID: nativeOffer.id, offerType: .external, origin: .external) }
                }
            }
            if nativeOffer.isModal {
                cancelFlow() {
                    report(nativeOffer)
                    Kin.shared.nativeOfferHandler?(nativeOffer)
                }
            } else {
                report(nativeOffer)
                Kin.shared.nativeOfferHandler?(nativeOffer)
            }
            return
        }
        switch offer.offerType {
        case .earn:
            
            showHTMLController(with: offer)
            
        default: // spend
            
            logError("native spend isn't supported")
            
        }
    }
    
    func offersViewControllerDidTapMyKinButton() {
        let myKinController = OrdersViewController(core: core)
        navigationControllerWrapper.pushViewController(myKinController, animated: true)
    }
    
    func showHTMLController(with offer: Offer) {
        
        let htmlController = EarnOfferViewController(core: core)
        htmlController.offerId = offer.id
        htmlController.delegate = self
        navigationControllerWrapper.present(htmlController, animated: true)
        
        if let type = KBITypes.OfferType(rawValue: offer.offerContentType.rawValue) {
            Kin.track { try EarnOfferTapped(kinAmount: Double(offer.amount), offerID: offer.id, offerType: type, origin: .marketplace) }
            Kin.track { try EarnOrderCreationRequested(kinAmount: Double(offer.amount), offerID: offer.id, offerType: type, origin: .marketplace) }
        }
        
        Flows.earn(offerId: offer.id, resultPromise: htmlController.earn, core: core)
    }
    
    func showNotEnoughKinController() {
        
    }
    
}

extension EntrypointFlowController: EarnOfferViewControllerDelegate {
    func earnOfferViewControllerDidFinish(_ controller: EarnOfferViewController) {
        guard controller.isBeingDismissed == false else { return }
        controller.dismiss(animated: true)
    }
}
