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
import StellarErrors
import KinUtil
import KinMigrationModule

let SDKVersion = "1.2.1"

public typealias KinUserStatsCallback = (UserStats?, Error?) -> ()
public typealias KinLoginCallback = (Error?) -> ()
public typealias KinCallback = (String?, Error?) -> ()
public typealias OrderConfirmationCallback = (ExternalOrderStatus?, Error?) -> ()

public enum ExternalOrderStatus {
    case pending
    case failed
    case completed(String)
}

public enum EcosystemExperience {
    case marketplace
    case history
    case backup((BREvent) -> ())
    case restore((BREvent) -> ())
}

extension EcosystemExperience: Equatable {
    public static func == (lhs: EcosystemExperience, rhs: EcosystemExperience) -> Bool {
        switch (lhs, rhs) {
        case (.marketplace, .marketplace): return true
        case (.history, .history): return true
        case (.backup, .backup): return true
        case (.restore, .restore): return true
        default: return false
        }
    }
}

public struct NativeOffer: Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let amount: Int32
    public let image: String
    public let isModal: Bool
    public let offerType: OfferType
    public init(id: String,
                title: String,
                description: String,
                amount: Int32,
                image: String,
                offerType: OfferType = .spend,
                isModal: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.amount = amount
        self.image = image
        self.isModal = isModal
        self.offerType = offerType
    }
}

public class Kin: NSObject {
    public static let shared = Kin()
    fileprivate(set) var core: Core?
    fileprivate weak var mpPresentingController: UIViewController?
    fileprivate var bi: BIClient!
    fileprivate var prestartBalanceObservers = [String : (Balance) -> ()]()
    fileprivate var prestartNativeOffers = [NativeOffer]()
    fileprivate let psBalanceObsLock = NSLock()
    fileprivate let psNativeOLock = NSLock()
    fileprivate var nativeOffersInc:Int32 = -1
    fileprivate var brManager:BRManager?
    fileprivate var entrypointFlowController: EntrypointFlowController?
    public var isLoggedIn:Bool { return UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue) != nil }
    // a temporary workaround to StellarKit.TransactionError.txBAD_SEQ
    fileprivate let purchaseQueue = OperationQueue()
    
    public var lastKnownBalance: Balance? {
        return core?.blockchain.lastBalance ?? nil
    }
    
    public var publicAddress: String? {
        return core?.blockchain.account?.publicAddress ?? nil
    }
    
    public var isActivated: Bool {
        return core?.onboarded ?? false
    }
    
    public var nativeOfferHandler: ((NativeOffer) -> ())?
    
    static func track<T: KBIEvent>(block: () throws -> (T)) {
        do {
            let event = try block()
            try Kin.shared.bi.send(event)
        } catch {
            logError("failed to send event, error: \(error)")
        }
    }

    override init() {
        super.init()

        UIFont.loadFonts(from: KinBundle.fonts.rawValue)
        purchaseQueue.maxConcurrentOperationCount = 1
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.purchaseQueue.isSuspended = true
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            self.purchaseQueue.isSuspended = false
        }
    }
    
    public func start(environment: Environment) throws {
        guard core == nil else {
            return
        }
        
        bi = try BIClient(endpoint: URL(string: environment.BIURL)!)
        setupBIProxies()
        
        guard   let modelPath = KinBundle.ecosystem.rawValue.path(forResource: "KinEcosystem",
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
        let network = EcosystemNet(config: EcosystemConfiguration(baseURL: marketplaceURL))
        core = try Core(environment: environment, network: network, data: store, blockchain: chain)
        
        psBalanceObsLock.lock()
        defer {
            psBalanceObsLock.unlock()
        }
        prestartBalanceObservers.forEach { identifier, block in
            _ = core!.blockchain.addBalanceObserver(with: block, identifier: identifier)
        }
        prestartBalanceObservers.removeAll()
        psNativeOLock.lock()
        defer {
            psNativeOLock.unlock()
        }
        try prestartNativeOffers.forEach({ offer in
            try add(nativeOffer: offer)
        })
        prestartNativeOffers.removeAll()
    }
    
    public func login(jwt: String, callback: KinLoginCallback? = nil) throws {
       
        Kin.track { try UserLoginRequested() }
       
        guard let core = core else {
            logError("Kin not started")
            let error = KinEcosystemError.client(.notStarted, nil)
            callback?(error)
            Kin.track { try UserLoginFailed(errorReason: error.localizedDescription) }
            throw error
        }
        
        let jwtObj = try JWTObject(with: jwt)
        
        DispatchQueue.once(token: "com.kin.init") {
           Kin.track { try KinSDKInitiated() }
        }
        
        let lastUser = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        let lastDevice = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInDevice.rawValue)
        let lastEnvironmentName = UserDefaults.standard.string(forKey: KinPreferenceKey.lastEnvironment.rawValue)
        
        var needsLogout = false
        if lastUser != jwtObj.userId ||
            lastEnvironmentName != core.environment.name ||
            lastDevice != jwtObj.deviceId {
            logInfo("user / environment / device change detected - logging out first...")
            UserDefaults.standard.set(false, forKey: KinPreferenceKey.firstSpendSubmitted.rawValue)
            UserDefaults.standard.removeObject(forKey: KinPreferenceKey.lastSignedInUser.rawValue)
            UserDefaults.standard.removeObject(forKey: KinPreferenceKey.lastSignedInDevice.rawValue)
            UserDefaults.standard.removeObject(forKey: KinPreferenceKey.lastEnvironment.rawValue)
            needsLogout = true
        }
        
        prepareLogin(needsLogout, jwt: jwtObj)
        .then {
            self.attempOnboard(core)
        }.then {
            UserDefaults.standard.set(jwtObj.userId, forKey: KinPreferenceKey.lastSignedInUser.rawValue)
            UserDefaults.standard.set(jwtObj.deviceId, forKey: KinPreferenceKey.lastSignedInDevice.rawValue)
            UserDefaults.standard.set(core.environment.name, forKey: KinPreferenceKey.lastEnvironment.rawValue)
            logInfo("blockchain onboarded successfully")
            Kin.track { try UserLoginSucceeded() }
            callback?(nil)
            _ = self.updateData(with: OffersList.self, from: "offers").error { error in
                logError("data sync failed (\(error))")
                }.then {
                    self.updateData(with: OrdersList.self, from: "orders").error { error in
                        logError("data sync failed (\(error))")
                    }
            }
        }.error { error in
            let tError = KinEcosystemError.transform(error)
            Kin.track { try UserLoginFailed(errorReason: tError.localizedDescription) }
            callback?(tError)
        }
    }
    
    public func logout() {
        guard let core = core else {
            logError("Kin not started")
            return
        }
        core.offboard()
    }
    
    public func balance(_ completion: @escaping (Balance?, Error?) -> ()) {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.client(.notStarted, nil))
            return
        }
        _ = attemptEx(2, closure: { attemptNum -> Promise<Balance> in
            core.onboard().then {
                core.blockchain.balance()
            }.then { balance in
                Promise<Balance>().signal(Balance(amount: balance))
            }
        }) { error -> Promise<Void> in
            self.recoverByMigratingIfNeeded(from: error)
        }.then(on: DispatchQueue.main) { balance in
            completion(balance, nil)
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
            }.error { error in
                completion(nil, KinEcosystemError.transform(error))
        }
        
    }
    
    public func addBalanceObserver(with block:@escaping (Balance) -> ()) -> String {
        guard let core = core else {
            psBalanceObsLock.lock()
            defer {
                psBalanceObsLock.unlock()
            }
            let observerIdentifier = UUID().uuidString
            prestartBalanceObservers[observerIdentifier] = block
            return observerIdentifier
        }
        return core.blockchain.addBalanceObserver(with: block)
    }
    
    public func removeBalanceObserver(_ identifier: String) {
        guard let core = core else {
            psBalanceObsLock.lock()
            defer {
                psBalanceObsLock.unlock()
            }
            prestartBalanceObservers[identifier] = nil
            return
        }
        core.blockchain.removeBalanceObserver(with: identifier)
    }
        
    @available(*, unavailable, renamed: "launchEcosystem(from:at:)")
    public func launchMarketplace(from parentViewController: UIViewController) throws {}
    
    public func launchEcosystem(from parentViewController: UIViewController, at experience: EcosystemExperience = .marketplace) throws {
        Kin.track { try EntrypointButtonTapped() }
        guard let core = core else {
            logError("Kin not started")
            throw KinEcosystemError.client(.notStarted, nil)
        }

        switch experience {
        case .marketplace, .history:
            mpPresentingController = parentViewController
            entrypointFlowController = EntrypointFlowController(presentingViewController: parentViewController, core: core)
            entrypointFlowController!.delegate = self
            entrypointFlowController!.start()

            if experience == .history {
                entrypointFlowController!.showTxHistory(pushAnimated: false)
            }
        case .backup(let handler):
            guard isActivated else { throw KinEcosystemError.service(.notLoggedIn, nil) }
            brManager = BRManager(with: self)
            brManager!.start(.backup, presentedOn: parentViewController) { success in
                if success {
                    handler(.backup(.done))
                } else {
                    handler(.backup(.cancel))
                }
            }
        case .restore(let handler):
            guard isActivated else { throw KinEcosystemError.service(.notLoggedIn, nil) }
            brManager = BRManager(with: self)
            brManager!.start(.restore, presentedOn: parentViewController) { success in
                if success {
                    handler(.restore(.done))
                } else {
                    handler(.restore(.cancel))
                }
            }
        }
    }
    
    public func hasAccount(peer: String, handler: @escaping (Bool?, Error?) -> ()) {
        guard let core = core else {
            logError("Kin not started")
            DispatchQueue.main.async {
                handler(nil, KinEcosystemError.client(.notStarted, nil))
            }
            return
        }
        _ = attemptEx(2, closure: { attemptNum -> Promise<Bool> in
            return core.onboard()
                .then {
                    core.network.dataAtPath("users/exists",
                                            method: .get,
                                            contentType: .json,
                                            parameters: ["user_id" : peer])
                }.then { data in
                    if  let response = String(data: data, encoding: .utf8),
                        let ans = Bool(response) {
                        return Promise<Bool>().signal(ans)
                    }
                    return Promise<Bool>().signal(KinEcosystemError.service(.response, nil))
                }
        }) { error -> Promise<Void> in
            self.recoverByMigratingIfNeeded(from: error)
        }.then { ans in
            DispatchQueue.main.async {
                handler(ans, nil)
            }
        }.error { error in
            DispatchQueue.main.async {
                handler(nil, KinEcosystemError.transform(error))
            }
        }
        
    }

    @discardableResult
    public func payToUser(offerJWT: String, completion: @escaping KinCallback) -> Bool {
        return purchase(offerJWT: offerJWT, completion: completion)
    }
    
    public func purchase(offerJWT: String, completion: @escaping KinCallback) -> Bool {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.client(.notStarted, nil))
            return false
        }
        defer {
            // a temporary workaround to StellarKit.TransactionError.txBAD_SEQ
            purchaseQueue.addOperation {
                let group = DispatchGroup()
                group.enter()
                let attempt = attemptEx(2, closure: { attemptNum -> Promise<String> in
                    return core.onboard()
                        .then {
                            Flows.nativeSpend(jwt: offerJWT, core: core)
                    }
                }) { error in
                    self.recoverByMigratingIfNeeded(from: error)
                    }.then { jwt in
                        completion(jwt, nil)
                    }.error { error in
                        completion(nil, KinEcosystemError.transform(error))
                }
                
                attempt.finally {
                    group.leave()
                }
                
                group.wait()
            }
        }
        return true
    }
    
    public func requestPayment(offerJWT: String, completion: @escaping KinCallback) -> Bool {
        guard let core = core else {
            logError("Kin not started")
            completion(nil, KinEcosystemError.client(.notStarted, nil))
            return false
        }
        defer {
            _ = attemptEx(2, closure: { attemptNum -> Promise<String> in
                core.onboard()
                    .then {
                        Flows.nativeEarn(jwt: offerJWT, core: core)
                }
            }) { error -> Promise<Void> in
               self.recoverByMigratingIfNeeded(from: error)
            }.then { jwt in
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
        _ = attemptEx(2, closure: { attemptNum -> Promise<ExternalOrderStatus> in
            let p = Promise<ExternalOrderStatus>()
            _ = core.onboard()
                .then {
                    self.updateData(with: OrdersList.self, from: "orders")
                }.then {
                    core.data.queryObjects(of: Order.self, with: NSPredicate(with: ["offer_id":offerID]), queryBlock: { orders in
                        guard let order = orders.first else {
                            let responseError = ResponseError(code: 4043, error: "NotFound", message: "Order not found")
                            p.signal(KinEcosystemError.service(.response, responseError))
                            return
                        }
                        switch order.orderStatus {
                        case .pending,
                             .delayed:
                            p.signal(.pending)
                        case .completed:
                            guard let jwt = (order.result as? JWTConfirmation)?.jwt else {
                                p.signal(KinEcosystemError.client(.internalInconsistency, nil))
                                break
                            }
                            p.signal(.completed(jwt))
                        case .failed:
                            p.signal(.failed)
                        }
                    }).error { error in
                        p.signal(error)
                    }
            }
            return p
        }) { error -> Promise<Void> in
            self.recoverByMigratingIfNeeded(from: error)
        }.then { status in
             completion(status, nil)
        }.error { error in
             completion(nil, KinEcosystemError.transform(error))
        }
        
    }
    
    public func setLogLevel(_ level: LogLevel) {
        Logger.setLogLevel(level)
    }
    
    public func add(nativeOffer: NativeOffer) throws {
        guard let core = core else {
            psNativeOLock.lock()
            defer {
                psNativeOLock.unlock()
            }
            prestartNativeOffers.append(nativeOffer)
            return
        }
        var offerExists = false
        core.data.queryObjects(of: Offer.self, with: NSPredicate(with: ["id" : nativeOffer.id])) { offers in
            offerExists = offers.count > 0
            }.then {
                guard offerExists == false else { return }
                core.data.stack.perform({ (context, _) in
                    let offer = try? Offer(with: nativeOffer, in: context)
                    offer?.position = self.nativeOffersInc
                    self.nativeOffersInc -= 1
                })
        }
    }
    
    public func remove(nativeOfferId: String) throws {
        guard let core = core else {
            psNativeOLock.lock()
            defer {
                psNativeOLock.unlock()
            }
            prestartNativeOffers = prestartNativeOffers.filter({ offer -> Bool in
                offer.id != nativeOfferId
            })
            return
        }
        _ = core.data.changeObjects(of: Offer.self, changeBlock: { context, offers in
            if let offer = offers.first {
                context.delete(offer)
            }
        }, with: NSPredicate(with: ["id" : nativeOfferId]))
    }
    
    public func userStats(handler: @escaping KinUserStatsCallback) {
        guard let core = core else {
            logError("Kin not started")
            handler(nil, KinEcosystemError.client(.notStarted, nil))
            return
        }
        
        _ = attemptEx(2, closure: { attemptNum -> Promise<UserStats?> in
            return core.onboard()
                .then {
                    core.network.objectAtPath("users/me", type: UserProfile.self)
                }.then { profile in
                    Promise<UserStats?>().signal(profile.stats)
                }
        }) { error -> Promise<Void> in
            self.recoverByMigratingIfNeeded(from: error)
        }.then(on: DispatchQueue.main) { stats in
            handler(stats, nil)
        }.error { error in
            DispatchQueue.main.async {
                handler(nil, KinEcosystemError.transform(error))
            }
        }
        
    }
    
    func prepareLogin(_ shouldLogout: Bool, jwt: JWTObject) -> Promise<Void> {
        guard let core = core else {
            return Promise<Void>().signal(KinEcosystemError.client(.notStarted, nil))
        }
        let p = Promise<Void>()
        guard shouldLogout else {
            core.jwt = jwt
            return p.signal(())
        }
        core.offboard().finally {
            core.jwt = jwt
            p.signal(())
        }
        return p
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
    
    func closeMarketPlace(completion: (() -> ())? = nil) {
        mpPresentingController?.dismiss(animated: true, completion: completion)
    }
    
    @discardableResult
    func attempOnboard(_ core: Core) -> Promise<Void> {
        return attempt(2) { attempNum -> Promise<Void> in
                let p = Promise<Void>()
                logInfo("attempting onboard: \(attempNum)")
                //logVerbose("accounts at onboard begin:\n\n\(core.blockchain.client.accounts.debugInfo)")
                core.onboard()
                        .then {
                            //logVerbose("accounts at onboard end:\n\n\(core.blockchain.client.accounts.debugInfo)")
                            p.signal(())
                        }
                        .error { error in
                            if case KinEcosystemError.service(.timeout, _) = error {
                                core.network.client.authToken = nil
                                Kin.track { try GeneralEcosystemSDKError(errorReason: "Blockchain onboard timedout at attempt \(attempNum), resetting auth token") }
                            }
                            p.signal(error)
                    }
                .error { error in
                    logError("onboard attempt failed: \(error)")
                    p.signal(error)
                }
                return p
            }.error { error in
                let errorDesc = "blockchain onboarding failed - \(error.localizedDescription)"
                logError(errorDesc)
                Kin.track { try GeneralEcosystemSDKError(errorReason: errorDesc) }
        }
    }
    
    func recoverByMigratingIfNeeded(from error: Error) -> Promise<Void> {
        if case let KinEcosystemError.service(.response, response) = KinEcosystemError.transform(error),
            let responseError = response as? ResponseError,
            responseError.code == 4101,
            let core = core {
            
            core.blockchain.offboard()
            
            return core.onboard()
        }
        return Promise<Void>().signal(error)
    }
    
 
    
    fileprivate func setupBIProxies() {
        EventsStore.shared.userProxy = UserProxy(balance: { [weak self] () -> (Double) in
            guard let balance = self?.core?.blockchain.lastBalance else {
                return 0
            }
            return NSDecimalNumber(decimal: balance.amount).doubleValue
            }, digitalServiceID: { [weak self] () -> (String) in
                return self?.core?.jwt?.appId ?? ""
            }, digitalServiceUserID: { [weak self] () -> (String) in
                return self?.core?.jwt?.userId ?? ""
            }, earnCount: { () -> (Int) in
                0
        }, entryPointParam: { () -> (String) in
            ""
        }, spendCount: { () -> (Int) in
            0
        }, totalKinEarned: { () -> (Double) in
            0
        }, totalKinSpent: { () -> (Double) in
            0
        }, transactionCount: { () -> (Int) in
            0
        })
        
        EventsStore.shared.clientProxy = ClientProxy(carrier: { [weak self] () -> (String) in
            return self?.bi.networkInfo.subscriberCellularProvider?.carrierName ?? ""
            }, deviceManufacturer: { () -> (String) in
                "Apple"
        }, deviceModel: { () -> (String) in
            UIDevice.current.model
        }, language: { () -> (String) in
            Locale.autoupdatingCurrent.languageCode ?? ""
        }, os: { () -> (String) in
            UIDevice.current.systemVersion
        })
        
        EventsStore.shared.commonProxy = CommonProxy(deviceID: { [weak self] () -> (String) in
            return self?.core?.jwt?.deviceId ?? ""
        }, eventID: { () -> (String) in
            UUID().uuidString
        }, timestamp: { () -> (String) in
            "\(Date().timeIntervalSince1970)"
        }, userID: { [weak self] () -> (String) in
            self?.core?.network.client.authToken?.ecosystem_user_id ?? ""
            }, version: { () -> (String) in
                SDKVersion
        })
    }
}

extension Kin: KinFlowControllerDelegate {
    func flowControllerDidComplete(_ controller: KinFlowController) {
        
    }
    
    func flowControllerDidCancel(_ controller: KinFlowController) {
        if controller is EntrypointFlowController {
            entrypointFlowController = nil
        }
    }
}


// MARK: Gifting Module

extension Kin {
    public static let giftingManager = GiftingManager()
}

