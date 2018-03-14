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
import KinUtil

enum KinEcosystemError: Error {
    case kinNotStarted
}

public class Kin {
    
    public static let shared = Kin()
    fileprivate(set) var core: Core?
    
    fileprivate init() { }
    
    @discardableResult
    public func start(apiKey: String, userId: String, appId: String, jwt: String? = nil, networkId: NetworkId = .testNet) -> Bool {
        guard core == nil else { return true }
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem",
                                               modelURL: URL(string: modelPath)!),
                let chain = try? Blockchain(networkId: networkId) else {
            // TODO: Analytics + no start
            logError("start failed")
            return false
        }
        var url: URL
        switch networkId {
        case .mainNet:
            url = URL(string: "http://api.kinmarketplace.com/v1")!
        default:
            url = URL(string: "http://localhost:3000/v1")!
        }
        //// testing / clearing users
        var shouldReset = false
        if let lastUser = UserDefaults.standard.string(forKey: "lastSignedInUser"),
            lastUser != userId {
            shouldReset = true
            logInfo("new user detected - resetting everything")
        }
        UserDefaults.standard.set(userId, forKey: "lastSignedInUser")
        ////
        if shouldReset {
            chain.resetAccount()
        }
        let network = EcosystemNet(config: EcosystemConfiguration(baseURL: url,
                                                                  apiKey: apiKey,
                                                                  appId: appId,
                                                                  userId: userId,
                                                                  jwt: jwt,
                                                                  publicAddress: chain.account.publicAddress))
        core = Core(network: network, data: store, blockchain: chain)
        
        if shouldReset {
            network.resetUser()
        }
        
        network.authorize().then {
            self.updateData(with: OffersList.self, from: "offers").then {
                self.updateData(with: OrdersList.self, from: "orders")
                }.error { error in
                    logError("data sync failed (\(error))")
            }
            self.core!.blockchain.onboard()
                .then {
                    logInfo("blockchain onboarded successfully")
                }
                .error(handler: { error in
                    logError("blockchain onboarding failed - \(error)")
                })
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
            }.error { error in
                logWarn("returning zero for balance because real balance retrieve failed, error: \(error)")
                completion(0)
        }
    }
    
    public func launchMarketplace(from parentViewController: UIViewController) {
        guard let core = core else {
            logError("Kin not started")
            return
        }
        
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
    
    func updateData<T: EntityPresentor>(with dataPresentorType: T.Type, from path: String) -> Promise<Void> {
        guard let core = core else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.kinNotStarted)
        }
        return core.network.getDataAtPath(path).then { data in
            logVerbose("network data: \(String(data: data, encoding: .utf8)!)")
            return self.core!.data.sync(dataPresentorType, with: data)
        }
    }
    
    
}
