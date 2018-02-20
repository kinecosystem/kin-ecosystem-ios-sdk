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
import StellarKit

enum KinEcosystemError: Error {
    case kinNotStarted
}

public class Kin {
    
    public static let shared = Kin()
    fileprivate(set) var network: EcosystemNet!
    fileprivate(set) var data: EcosystemData!
    fileprivate(set) var blockchain: Blockchain!
    fileprivate(set) var started = false
    
    fileprivate init() { }
    
    @discardableResult
    public func start(apiKey: String, userId: String, jwt: String? = nil, networkId: NetworkId = .testNet) -> Bool {
        guard started == false else { return true }
        guard   let modelPath = Bundle.ecosystem.path(forResource: "KinEcosystem",
                                                      ofType: "momd"),
                let store = try? EcosystemData(modelName: "KinEcosystem",
                                               modelURL: URL(string: modelPath)!),
                let chain = try? Blockchain(networkId: networkId) else {
            // TODO: Analytics + no start
            logError("start failed")
            return false
        }
        blockchain = chain
        data = store
        var url: URL
        switch networkId {
        case .mainNet:
            url = URL(string: "http://api.kinmarketplace.com/v1")!
        default:
            url = URL(string: "http://localhost:3000/v1")!
        }
        network = EcosystemNet(config: EcosystemConfiguration(baseURL: url, apiKey: apiKey, userId: userId, jwt: jwt, publicAddress: blockchain.account.publicAddress))
        started = true
        // TODO: move this to dev initiated (not on start)
        updateData(with: OffersList.self, from: "offers").then {
            self.updateData(with: OrdersList.self, from: "orders")
            }.error { error in
                logError("data sync failed")
        }
        return true
    }

    public func balance(_ completion: @escaping (Decimal) -> ()) {
        blockchain.balance().then(on: DispatchQueue.main) { balance in
            completion(balance)
            }.error { error in
                logWarn("returning zero for balance because real balance retrieve failed, error: \(error)")
                completion(0)
        }
    }
    
    public func launchMarketplace(from parentViewController: UIViewController) {
        guard started else {
            logError("Kin not started")
            return
        }
        
        let mpViewController = MarketplaceViewController(nibName: "MarketplaceViewController", bundle: Bundle.ecosystem)
        mpViewController.data = data
        mpViewController.network = network
        mpViewController.blockchain = blockchain
        let navigationController = KinBaseNavigationController(rootViewController: mpViewController)
        parentViewController.present(navigationController, animated: true)
    }
    
    func onboard() -> Promise<Bool> {
        let p = Promise<Bool>()

        if blockchain.onboarded {
            return p.signal(true)
        }

        let activate = {
            self.blockchain.account.activate(passphrase: "") { _, error in
                if let error = error {
                    p.signal(error)

                    return
                }

                self.blockchain.onboarded = true

                p.signal(true)
            }
        }

        blockchain.balance()
            .then { _ in
                self.blockchain.onboarded = true

                p.signal(true)
            }
            .error { (bError) in
                if case let KinError.balanceQueryFailed(error) = bError {
                    if let error = error as? StellarError {
                        switch error {
                        case .missingAccount:
                            self.network.create(account: self.blockchain.account.publicAddress)
                                .then { _ in
                                    activate()
                                }
                                .error { error in
                                    p.signal(error)
                            }
                            break
                        case .missingBalance:
                            activate()
                        default:
                            p.signal(KinError.unknown)
                        }
                    }
                    else {
                        p.signal(bError)
                    }
                }
                else {
                    p.signal(bError)
                }
        }

        return p
    }

    func updateData<T: EntityPresentor>(with dataPresentorType: T.Type, from path: String) -> Promise<Void> {
        guard started else {
            logError("Kin not started")
            return Promise<Void>().signal(KinEcosystemError.kinNotStarted)
        }
        return network.getDataAtPath(path).then { data in
            self.data.sync(dataPresentorType, with: data)
        }
    }
    
}
