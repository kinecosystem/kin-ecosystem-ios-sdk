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
import StellarErrors

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
    
    public func start(apiKey: String, userId: String, appId: String, jwt: String? = nil, environment: Environment) throws {
        guard core == nil else {
            return
        }
        let lastUser = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        var environmentChanged = true
        if  let lastEnvironmentPropertiesData = UserDefaults.standard.data(forKey: KinPreferenceKey.lastEnvironment.rawValue),
            let props = try? JSONDecoder().decode(EnvironmentProperties.self, from: lastEnvironmentPropertiesData), props == environment.properties {
            environmentChanged = false
        }
        if lastUser != userId {
            needsReset = true
            logInfo("new user detected - resetting everything")
            UserDefaults.standard.set(false, forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
        }
        if environmentChanged {
            needsReset = true
            logInfo("environment change detected - resetting everything")
            if let data = try? JSONEncoder().encode(environment.properties) {
                UserDefaults.standard.set(data, forKey: KinPreferenceKey.lastEnvironment.rawValue)
            }
        }
        UserDefaults.standard.set(userId, forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd") else {
            logError("start failed")
            throw KinEcosystemError.client(.internalInconsistency, nil)
        }
        let store: EcosystemData!
        let chain: Blockchain!
        do {
            store = try EcosystemData(modelName: "KinEcosystem",
                                      modelURL: URL(string: modelPath)!)
            chain = try Blockchain(environment: environment)
        } catch {
            logError("start failed")
            throw KinEcosystemError.client(.internalInconsistency, nil)
        }
        
        guard let marketplaceURL = URL(string: environment.marketplaceURL) else {
            throw KinEcosystemError.client(.badRequest, nil)
        }
        let network = EcosystemNet(config: EcosystemConfiguration(baseURL: marketplaceURL,
                                                                  apiKey: apiKey,
                                                                  appId: appId,
                                                                  userId: userId,
                                                                  jwt: jwt,
                                                                  publicAddress: chain.account.publicAddress))
        core = Core(environment: environment, network: network, data: store, blockchain: chain)
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
            completion(nil, KinEcosystemError.client(.notStarted, nil))
            return
        }
        core.blockchain.balance().then(on: DispatchQueue.main) { balance in
            completion(Balance(amount: balance), nil)
            }.error { error in
                let esError: KinEcosystemError
                switch error {
                    case KinError.internalInconsistency,
                         KinError.accountDeleted:
                        esError = KinEcosystemError.client(.internalInconsistency, error)
                    case KinError.balanceQueryFailed(let queryError):
                        switch queryError {
                        case StellarError.missingAccount:
                            esError = KinEcosystemError.blockchain(.notFound, error)
                        case StellarError.missingBalance:
                            esError = KinEcosystemError.blockchain(.activation, error)
                        case StellarError.unknownError:
                            esError = KinEcosystemError.unknown(.unknown, error)
                        default:
                            esError = KinEcosystemError.unknown(.unknown, error)
                        }
                    default:
                        esError = KinEcosystemError.unknown(.unknown, error)
                }
                completion(nil, esError)
        }
    }
    
    public func addBalanceObserver(with block:@escaping (Balance) -> ()) throws -> String {
        guard let core = core else {
            logError("Kin not started")
            throw KinEcosystemError.client(.notStarted, nil)
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
            completion(nil, KinEcosystemError.client(.notStarted, nil))
            return false
        }
        defer {
            Flows.nativeSpend(jwt: offerJWT, core: core).then { jwt in
                completion(jwt, nil)
                }.error { error in
                    completion(nil, KinEcosystemError.transform(error))
            }
        }
        return true
    }
    
    public func orderConfirmation(for offerID: String, completion: @escaping OrderConfirmationCallback) {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.client(.notStarted, nil))
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
                        let responseError = ResponseError(code: 4043, error: "NotFound", message: "Order not found")
                        completion(nil, KinEcosystemError.service(.response, responseError))
                        return
                    }
                    switch order.orderStatus {
                    case .pending,
                         .delayed:
                       completion(.pending, nil)
                    case .completed:
                        guard let jwt = (order.result as? JWTConfirmation)?.jwt else {
                            completion(nil, KinEcosystemError.client(.internalInconsistency, nil))
                            return
                        }
                        completion(.completed(jwt), nil)
                    case .failed:
                        completion(.failed, nil)
                    }
                })
            }.error { error in
                completion(nil, KinEcosystemError.transform(error))
        }
    }
    
    public func setLogLevel(_ level: LogLevel) {
        Logger.setLogLevel(level)
    }
    
    func updateData<T: EntityPresentor>(with dataPresentorType: T.Type, from path: String) -> Promise<Void> {
        guard let core = core else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.client(.notStarted, nil))
        }
        return core.network.dataAtPath(path).then { data in
            return self.core!.data.sync(dataPresentorType, with: data)
        }
    }
    
    func closeMarketPlace() {
        mpPresentingController?.dismiss(animated: true, completion: nil)
    }
}
