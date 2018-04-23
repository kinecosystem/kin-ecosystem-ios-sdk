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

public typealias PurchaseCallback = (String?, Error?) -> ()
public typealias OrderConfirmationCallback = (ExternalOrderStatus?, Error?) -> ()

public enum ExternalOrderStatus {
    case pending
    case failed
    case completed(String)
}
@available(iOS 9.0, *)
public class Kin {
    
    public static let shared = Kin()
    fileprivate(set) var core: Core?
    fileprivate(set) var needsReset = false
    fileprivate weak var mpPresentingController: UIViewController?
    fileprivate init() { }
    
    public var lastKnownBalance: Balance? {
        guard let core = Kin.shared.core else {
            return nil
        }
        return core.blockchain.lastBalance
    }
    
    public var publicAddres: String? {
        guard let core = Kin.shared.core else {
            return nil
        }
        return core.blockchain.account.publicAddress
    }
    
    public var isActivated: Bool {
        guard let core = Kin.shared.core else {
            return false
        }
        return core.blockchain.onboarded && core.network.tosAccepted
    }
    
    public func start(apiKey: String, userId: String, appId: String, jwt: String? = nil, networkId: NetworkId = .testNet) throws {
        guard core == nil else {
            return
        }
        let lastUser = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        if lastUser != userId {
            needsReset = true
            logInfo("new user detected - resetting everything")
            UserDefaults.standard.set(false, forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
        }
        UserDefaults.standard.set(userId, forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd") else {
            logError("start failed")
            throw KinEcosystemError.startFailed(KinError.internalInconsistency)
        }
        let store: EcosystemData!
        let chain: Blockchain!
        do {
            store = try EcosystemData(modelName: "KinEcosystem",
                                      modelURL: URL(string: modelPath)!)
            chain = try Blockchain(networkId: networkId)
        } catch {
            logError("start failed")
            throw KinEcosystemError.startFailed(error)
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
        let tosAccepted = core!.network.tosAccepted
        network.authorize().then { [weak self] in
            self?.core!.blockchain.onboard()
                .then {
                    logInfo("blockchain onboarded successfully")
                }
                .error { error in
                    logError("blockchain onboarding failed - \(error)")
            }
            self?.updateData(with: OffersList.self, from: "offers").error { error in
                    logError("data sync failed (\(error))")
            }
            if tosAccepted {
                self?.updateData(with: OrdersList.self, from: "orders").error { error in
                    logError("data sync failed (\(error))")
                }
            }
        }
        
        
        
    }
    
    public func balance(_ completion: @escaping (Balance?, Error?) -> ()) {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.notStarted)
            return
        }
        core.blockchain.balance().then(on: DispatchQueue.main) { balance in
            completion(Balance(amount: balance), nil)
            }.error { error in
                completion(nil, KinEcosystemError.blockchain(error))
        }
    }
    
    public func addBalanceObserver(with block:@escaping (Balance) -> ()) throws -> String {
        guard let core = core else {
            logError("Kin not started")
            throw KinEcosystemError.notStarted
        }
        return try core.blockchain.addBalanceObserver(with: block)
    }
    
    public func removeBalanceObserver(_ identifier: String) {
        guard let core = core else {
            logError("Kin not started")
            return
        }
        core.blockchain.removeBalanceObserver(with: identifier)
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
            completion(nil, KinEcosystemError.notStarted)
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
    
    public func orderConfirmation(for offerID: String, completion: @escaping OrderConfirmationCallback) {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.notStarted)
            return
        }
        core.network.authorize().then { [weak self] () -> Promise<Void> in
            guard let this = self else {
                return Promise<Void>().signal(KinError.internalInconsistency)
            }
            return this.updateData(with: OrdersList.self, from: "orders")
            }.then { 
                core.data.queryObjects(of: Order.self, with: NSPredicate(with: ["offer_id":offerID]), queryBlock: { orders in
                    guard let order = orders.first else {
                        completion(nil, KinEcosystemError.notFound)
                        return
                    }
                    switch order.orderStatus {
                    case .pending,
                         .delayed:
                       completion(.pending, nil)
                    case .completed:
                        guard let jwt = (order.result as? JWTConfirmation)?.jwt else {
                            completion(nil, KinEcosystemError.service)
                            return
                        }
                        completion(.completed(jwt), nil)
                    case .failed:
                        completion(.failed, nil)
                    }
                })
            }.error { error in
              completion(nil, KinEcosystemError.internal(error))
        }
    }
    
    public func setLogLevel(_ level: LogLevel) {
        Logger.setLogLevel(level)
    }
    
    func updateData<T: EntityPresentor>(with dataPresentorType: T.Type, from path: String) -> Promise<Void> {
        guard let core = core else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.notStarted)
        }
        return core.network.dataAtPath(path).then { data in
            return self.core!.data.sync(dataPresentorType, with: data)
        }
    }
    
    func closeMarketPlace() {
        mpPresentingController?.dismiss(animated: true, completion: nil)
    }
}
