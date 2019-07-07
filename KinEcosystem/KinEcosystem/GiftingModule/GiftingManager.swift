//
//  GiftingManager.swift
//  KinEcosystem
//
//  Created by Corey Werner on 04/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit
import KinAppreciationModuleOptionsMenu

public protocol GiftingManagerDelegate: NSObjectProtocol {
    func giftingManagerDidPresent(_ giftingManager: GiftingManager)
    func giftingManagerDidCancel(_ giftingManager: GiftingManager)
    func giftingManagerNeedsJWT(_ giftingManager: GiftingManager, amount: Decimal) -> String?
    func giftingManager(_ giftingManager: GiftingManager, didCompleteWith jwtConfirmation: String)
    func giftingManager(_ giftingManager: GiftingManager, error: Error)
}

public class GiftingManager: NSObject {
    public weak var delegate: GiftingManagerDelegate?

    fileprivate var isActive = false

    private func setupViewController(balance: Decimal) -> KinAppreciationViewController {
        let viewController = KinAppreciationViewController(balance: balance, theme: .light)
        viewController.delegate = self
        viewController.biDelegate = self
        return viewController
    }

    public func present(in viewController: UIViewController) {
        guard !isActive else {
            delegate?.giftingManager(self, error: KinEcosystemError.client(.activeGift, nil))
            return
        }

        isActive = true

        if let balance = Kin.shared.lastKnownBalance {
            let giftingViewController = setupViewController(balance: balance.amount)
            viewController.present(giftingViewController, animated: true)
        }
        else {
            Kin.shared.balance { [self] (balance, error) in
                if let error = error {
                    self.isActive = false
                    self.delegate?.giftingManager(self, error: error)
                }
                else {
                    let giftingViewController = self.setupViewController(balance: balance?.amount ?? 0)
                    viewController.present(giftingViewController, animated: true)
                }
            }
        }
    }
}

extension GiftingManager: KinAppreciationViewControllerDelegate {
    public func kinAppreciationViewControllerDidPresent(_ viewController: KinAppreciationViewController) {
        delegate?.giftingManagerDidPresent(self)
    }

    public func kinAppreciationViewController(_ viewController: KinAppreciationViewController, didDismissWith reason: KinAppreciationCancelReason) {
        isActive = false
        delegate?.giftingManagerDidCancel(self)
    }

    public func kinAppreciationViewController(_ viewController: KinAppreciationViewController, didSelect amount: Decimal) {
        guard let jwt = delegate?.giftingManagerNeedsJWT(self, amount: amount) else {
            isActive = false
            delegate?.giftingManager(self, error: KinEcosystemError.client(.jwtMissing, nil))
            return
        }

        Kin.shared.payToUser(offerJWT: jwt) { [self] (jwtConfirmation, error) in
            self.isActive = false

            if let error = error {
                self.delegate?.giftingManager(self, error: error)
            }
            else {
                self.delegate?.giftingManager(self, didCompleteWith: jwtConfirmation ?? "")
            }
        }
    }
}

extension GiftingManager: KinAppreciationBIDelegate {
    public func kinAppreciationDidAppear() {
        Kin.track { try APageViewed(pageName: .giftingDialog) }
    }

    public func kinAppreciationDidSelect(amount: Decimal) {
        Kin.track { try GiftingButtonTapped(kinAmount: NSDecimalNumber(decimal: amount).doubleValue) }
    }

    public func kinAppreciationDidCancel(reason: KinAppreciationCancelReason) {
        Kin.track { try PageCloseTapped(exitType: reason.biMap, pageName: .giftingDialog) }
    }

    public func kinAppreciationDidComplete() {
        Kin.track { try GiftingFlowCompleted() }
    }
}

extension KinAppreciationCancelReason {
    var biMap: KBITypes.ExitType {
        switch self {
        case .closeButton:
            return .xButton
        case .hostApplication:
            return .hostApp
        case .touchOutside:
            return .backgroundApp
        }
    }
}
