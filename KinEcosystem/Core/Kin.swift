//
//
//  Kin.swift
//
//  Created by Kin Foundation
//  Copyright © 2018 Kin Foundation. All rights reserved.
//
//  kinecosystem.org
//

import Foundation
import KinSDK

enum KinEcosystemError: Error {
    case kinNotStarted
}

public typealias PurchaseCallback = (String?, Error?) -> ()

public class Kin {
    
    public static let shared = Kin()
    fileprivate(set) var core: Core?
    fileprivate(set) var needsReset = false
    fileprivate weak var mpPresentingController: UIViewController?
    fileprivate init() { }
    
    public var balanceObserver: Observable<StatfulBalance>? {
        guard let core = Kin.shared.core else {
            return nil
        }
        return core.blockchain.currentBalance
    }
    
    public var publicAddres: String? {
        guard let core = Kin.shared.core else {
            return nil
        }
        return core.blockchain.account.publicAddress
    }
    
    @discardableResult
    public func start(apiKey: String, userId: String, appId: String, jwt: String? = nil, networkId: NetworkId = .testNet, completion: ((Error?) -> ())? = nil) -> Bool {
        guard core == nil else {
            completion?(nil)
            return true
        }
        if let  lastUser = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue),
            lastUser != userId {
            needsReset = true
            logInfo("new user detected - resetting everything")
            UserDefaults.standard.set(false, forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
        }
        UserDefaults.standard.set(userId, forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem",
                                               modelURL: URL(string: modelPath)!),
                let chain = try? Blockchain(networkId: networkId) else {
            logError("start failed")
            completion?(KinError.internalInconsistency)
            return false
        }
        var url: URL
        switch networkId {
        case .mainNet:
            url = URL(string: "http://api.kinmarketplace.com/v1")!
        default:
            url = URL(string: "http://api.kinmarketplace.com/v1")!
        }
        let network = EcosystemNet(config: EcosystemConfiguration(baseURL: url,
                                                                  apiKey: apiKey,
                                                                  appId: appId,
                                                                  userId: userId,
                                                                  jwt: jwt,
                                                                  publicAddress: chain.account.publicAddress))
        core = Core(network: network, data: store, blockchain: chain)
        
        network.authorize().then {
            self.updateData(with: OffersList.self, from: "offers").then {
                self.updateData(with: OrdersList.self, from: "orders")
                }.error { error in
                    logError("data sync failed (\(error))")
            }
            self.core!.blockchain.onboard()
                .then {
                    logInfo("blockchain onboarded successfully")
                    completion?(nil)
                }
                .error { error in
                    logError("blockchain onboarding failed - \(error)")
                    completion?(error)
            }
        }
        return true
    }
    
    public func balance(_ completion: @escaping (Decimal) -> ()) {
        guard let core = core else {
            logError("Kin not started")
            return
        }
        core.blockchain.balance().then(on: DispatchQueue.main) { balance in
            completion(balance)
            }.error { _ in
                completion(0)
        }
    }
    
    public func launchMarketplace(from parentViewController: UIViewController) {
        guard let core = core else {
            logError("Kin not started")
            return
        }
        mpPresentingController = parentViewController
        if core.network.tosAccepted {
            let mpViewController = MarketplaceViewController(nibName: "MarketplaceViewController", bundle: Bundle.ecosystem)
            mpViewController.core = core
            let navigationController = KinNavigationViewController(nibName: "KinNavigationViewController",
                                                                   bundle: Bundle.ecosystem,
                                                                   rootViewController: mpViewController)
            navigationController.core = core
            parentViewController.present(navigationController, animated: true)
        } else {
            let welcomeVC = WelcomeViewController(nibName: "WelcomeViewController", bundle: Bundle.ecosystem)
            welcomeVC.core = core
            parentViewController.present(welcomeVC, animated: true)
        }
        
    }
    
    public func purchase(offerJWT: String, completion: @escaping PurchaseCallback) -> Bool {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.kinNotStarted)
            return false
        }
        defer {
            Flows.nativeSpend(jwt: offerJWT, core: core).then { jwt in
                completion(jwt, nil)
                }.error { error in
                    completion(nil, error)
            }
        }
        return true
    }
    
    func updateData<T: EntityPresentor>(with dataPresentorType: T.Type, from path: String) -> Promise<Void> {
        guard let core = core else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.kinNotStarted)
        }
        return core.network.dataAtPath(path).then { data in
            return self.core!.data.sync(dataPresentorType, with: data)
        }
    }
    
    func closeMarketPlace() {
        mpPresentingController?.dismiss(animated: true, completion: nil)
    }
}
