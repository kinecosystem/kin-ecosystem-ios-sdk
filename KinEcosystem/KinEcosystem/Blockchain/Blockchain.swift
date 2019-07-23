//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import StellarErrors
import KinMigrationModule

struct KinAccountExtraData: Codable {
    var user: String?
    var kinUserId: String?
    var environment: String?
    var onboarded: Bool
    var lastActive: Date
    var backedUp: Bool
}

struct KinImportedAccountData: Decodable{
    let pkey: String
    let seed: String
    let salt: String
}

enum PaymentMemoIdentifier: CustomStringConvertible, Equatable, Hashable {
    case raw(String)
    case components(appId: String, id: String)

    var hashValue: Int {
        return description.hashValue
    }

    static private let version = "1"

    var description: String {
        switch self {
        case .raw(let memo):
            return memo
        case .components(appId: let appId, id: let memoId):
            return "\(PaymentMemoIdentifier.version)-\(appId)-\(memoId)"
        }
    }

    static func ==(lhs: PaymentMemoIdentifier, rhs: PaymentMemoIdentifier) -> Bool {
        return lhs.description == rhs.description
    }
}

enum BlockchainError: Error {
    case watchNotStarted
    case watchTimedOut
}

enum TimeoutPolicy {
    case fail
    case ignore
}

class Blockchain: NSObject {
    var lastKnownWalletAddress: String?
    var versionQuery: (() -> Promise<KinVersion>)?
    var blockchainVersion: String {
        get {
            guard let version = migrationManager?.version else {
                return "2"
            }
            if case .kinCore = version {
                return "2"
            }
            return "3"
        }
    }
    fileprivate(set) var account: KinAccountProtocol? {
        didSet {
            if let ac = account {
                if balanceObservers.count > 0 {
                    watchBalance(for: ac)
                }
            } else {
                unwatchBalance()
            }
        }
    }
    private var importedAccount: (String, String)?
    private let linkBag = LinkBag()
    private var paymentObservers = [PaymentMemoIdentifier: Observable<String>]()
    private var balanceObservers = [String: (Balance) -> ()]()
    private var paymentsWatcher: PaymentWatchProtocol?
    private var balanceWatcher: BalanceWatchProtocol?
    private var kinAuthToken: AuthToken?
    private var client: KinClientProtocol?
    private(set) var migrationManager: KinMigrationManager?
    private var startingAddress: String?
    private(set) var onboardInFlight = false
    private(set) var accountPromise = Promise<KinAccountProtocol>()
    private var isOnboarding: Bool {
        get {
            var result: Bool!
            synced(self) {
                result = onboardInFlight
            }
            return result
        }
        set {
            synced(self) {
                onboardInFlight = newValue
            }
        }
    }
    var isBackedUp: Bool {
        get {
            return account?.kinExtraData.backedUp ?? false
        }
    }

    private var onboardPromise = Promise<Void>()
    private var onboardLock: Int = 1
    private let environment: Environment
    fileprivate(set) var balanceObservable = Observable<Balance>()
    fileprivate(set) var lastBalance: Balance? {
        get {
            guard account != nil else { return nil }
            if  let data = UserDefaults.standard.data(forKey: KinPreferenceKey.lastBalance.rawValue),
                let cachedBalance = try? JSONDecoder().decode(Balance.self, from: data) {
                    return cachedBalance
            }
            return nil
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            if let balance = newValue {
                balanceObservable.next(balance)
            } else {
                UserDefaults.standard.set(nil, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            updateBalanceObservers(newValue ?? Balance(amount: 0))
        }


    }
    fileprivate(set) var onboarded: Bool {
        get {
            var result: Bool!
            synced(onboardLock) {
                result = account?.kinExtraData.onboarded ?? false
            }
            return result
        }
        set {
            isOnboarding = false
            guard newValue else {
                synced(onboardLock) {
                    lastKnownWalletAddress = nil
                    lastBalance = nil
                    account = nil
                    client = nil
                    startingAddress = nil
                }
                return
            }
            synced(onboardLock) {
                if  var account = account,
                    let kinUserId = kinAuthToken?.ecosystem_user_id {
                    var kinExtraData = account.kinExtraData
                    kinExtraData.onboarded = true
                    kinExtraData.kinUserId = kinUserId
                    kinExtraData.environment = environment.name
                    kinExtraData.lastActive = Date()
                    account.kinExtraData = kinExtraData
                }
            }
        }
    }

    init(environment: Environment) throws {
        self.environment = environment
    }
    
    func start(with token: AuthToken, publicAddress: String?) throws {
        startingAddress = publicAddress
        migrationManager = KinMigrationManager(serviceProvider: try environment.mapToMigrationModuleServiceProvider(), appId: try AppId(token.app_id))
        migrationManager!.delegate = self
        migrationManager!.biDelegate = self
        kinAuthToken = token
        accountPromise = Promise<KinAccountProtocol>()
        cleanup()
        try migrationManager!.start(with: publicAddress)
    }
    
    func importAccount(info: (String, String), byMigratingFirst migrate: Bool) -> Promise<Void> {
        let p = Promise<Void>()
        guard let mm = migrationManager else {
            return p.signal(KinEcosystemError.client(.internalInconsistency, nil))
        }
        guard let data = info.0.data(using: .utf8),
            let accountData = try? JSONDecoder().decode(KinImportedAccountData.self, from: data) else {
                return p.signal(KinEcosystemError.client(.accountReadFailed, nil))
        }
        
        guard validateAccountPassword(accountData, password: info.1) else {
            return p.signal(KinEcosystemError.blockchain(.invalidPassword, nil))
        }
        if migrate {
            let coreClient = mm.kinClient(version: .kinCore)
            if coreClient.accounts.makeIterator().first(where: { $0.publicAddress == accountData.pkey }) == nil {
                do {
                    _ = try coreClient.importAccount(info.0, passphrase: info.1)
                } catch {
                    p.signal(error)
                }
            }
        }
        self.importedAccount = info
        self.accountPromise = Promise<KinAccountProtocol>()
        do {
            try mm.start(with: accountData.pkey)
            p.signal(())
        } catch {
            p.signal(error)
        }
        
        return p
    }
    
    func validateAccountPassword(_ accountData: KinImportedAccountData, password: String) -> Bool {
        
        let eseed = accountData.seed
        let salt = accountData.salt

        guard let newSalt = KeyUtils.salt() else {
             return false
        }

        guard   let skey = try? KeyUtils.keyHash(passphrase: "", salt: newSalt),
                let seed = try? KeyUtils.seed(from: password, encryptedSeed: eseed, salt: salt),
                let _ = KeyUtils.encryptSeed(seed, secretKey: skey) else {
            return false
        }
        
        return true
    }
    
    func setActiveAccount(_ anAccount: KinAccountProtocol) throws {
        lastKnownWalletAddress = anAccount.publicAddress
        guard let token = kinAuthToken else { throw KinEcosystemError.service(.notLoggedIn, nil) }
        account = anAccount
        guard var ac = account else {throw KinEcosystemError.client(.internalInconsistency, nil) }
        var data = ac.kinExtraData
        data.lastActive = Date()
        data.environment = environment.name
        data.kinUserId = token.ecosystem_user_id
        ac.kinExtraData = data
        _ = balance()
    }
    
    func createNewAccount() throws -> KinAccountProtocol {
        guard let token = kinAuthToken, let client = client else { throw KinEcosystemError.service(.notLoggedIn, nil) }
        Kin.track { try StellarAccountCreationRequested() }
        var result = try client.addAccount()
        var kinExtraData = result.kinExtraData
        kinExtraData.kinUserId = token.ecosystem_user_id
        kinExtraData.user = token.user_id
        kinExtraData.environment = environment.name
        result.kinExtraData = kinExtraData
        return result
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        guard let account = account else {
            p.signal(KinEcosystemError.service(.notLoggedIn, nil))
            return p
        }
        account.balance().then { [weak self] kin in
            self?.lastBalance = Balance(amount: kin)
            p.signal(kin)
            }.error { error in
                p.signal(error)
        }
        return p
    }

    func onboard() -> Promise<Void> {
       
        if onboarded {
            return Promise<Void>().signal(())
        }
        
        if isOnboarding {
            return onboardPromise
        }
        
        onboardPromise = Promise<Void>()
        isOnboarding = true
        
        guard let account = account else {
            onboardPromise.signal(KinEcosystemError.service(.notLoggedIn, nil))
            return onboardPromise
        }
        
        balance()
            .then { _ in
                self.onboardPromise.signal(())
                self.onboarded = true
            }
            .error { (bError) in
                    if let error = bError as? KinError {
                        switch error {
                        case .missingAccount:
                            self.watchAccountCreation(timeout: 15.0)
                                .then { _ in
                                    Kin.track { try WalletCreationSucceeded() }
                                    self.onboardPromise.signal(())
                                    self.onboarded = true
                                }.error { error in
                                    self.onboardPromise.signal(error)
                                    self.onboarded = false
                                }
                            
                        case .missingBalance:
                            account.activate().then { _ in
                                Kin.track { try WalletCreationSucceeded() }
                                self.onboardPromise.signal(())
                                self.onboarded = true
                            }.error { error in
                                self.onboardPromise.signal(error)
                                self.onboarded = false
                            }
                        default:
                            self.onboardPromise.signal(error)
                            self.onboarded = false
                        }
                    } else {
                        self.onboardPromise.signal(bError)
                        self.onboarded = false
                    }
        }

        return onboardPromise
    }
    
    func offboard() {
        onboarded = false
    }


    func pay(to recipient: String, kin: Decimal, memo: String?, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId> {
        guard let account = account else { return Promise<TransactionId>().signal(KinEcosystemError.service(.notLoggedIn, nil)) }
        return account.sendTransaction(to: recipient, kin: kin, memo: memo, fee: 0, whitelist: whitelist)
    }
    
    func generateTransactionData(to recipient: String, kin: Decimal, memo: String?, fee: Stroop) -> Promise<Data> {
        guard let account = account else { return Promise<Data>().signal(KinEcosystemError.service(.notLoggedIn, nil)) }
        let p = Promise<Data>()
        _ = account.sendTransaction(to: recipient, kin: kin, memo: memo, fee: fee) { envelope -> (Promise<TransactionEnvelope?>) in
            do {
                let wlEnvelope = EcosystemWhitelistEnvelope(transactionEnvelope: envelope)
                let encoded = try JSONEncoder().encode(wlEnvelope)
                p.signal(encoded)
            } catch {
                p.signal(error)
            }
            return Promise<TransactionEnvelope?>().signal(nil)
        }.error { error in
              p.signal(error)
        }
        return p
        
    }

    func startWatchingForNewPayments(with memo: PaymentMemoIdentifier) throws {
        defer {
            logInfo("added watch for \(memo)...")
            paymentObservers[memo] = Observable<String>()
        }

        guard paymentsWatcher == nil else {
            logInfo("payment watcher already started")
            return
        }

        guard let account = account else { throw KinEcosystemError.service(.notLoggedIn, nil) }
        paymentsWatcher = try account.watchPayments(cursor: "now")
        paymentsWatcher?.emitter.on(next: { [weak self] paymentInfo in
            guard let metadata = paymentInfo.memoText else { return }
            guard let match = self?.paymentObservers.first(where: { memoKey, _ in
                memoKey.description == metadata
            })?.value else { return }
            logInfo("payment found in blockchain for \(metadata)...")
            match.next(paymentInfo.hash)
            match.finish()
        }).add(to: linkBag)
    }

    func stopWatchingForNewPayments(with memo: PaymentMemoIdentifier? = nil) {
        guard let memo = memo else {
            paymentObservers.removeAll()
            paymentsWatcher = nil
            logInfo("removed all payment observers")
            return
        }
        paymentObservers.removeValue(forKey: memo)
        if paymentObservers.count == 0 {
            paymentsWatcher = nil
        }
        logInfo("removed payment observer for \(memo)")
    }

    func waitForNewPayment(with memo: PaymentMemoIdentifier, timeout: TimeInterval = 300.0, policy: TimeoutPolicy = .fail) -> Promise<String?> {
        let p = Promise<String?>()
        guard paymentObservers.keys.contains(where: { key -> Bool in
            key == memo
        }) else {
            return p.signal(BlockchainError.watchNotStarted)
        }
        var found = false
        paymentObservers[memo]?.on(next: { [weak self] txHash in
            found = true
            _ = self?.balance()
            p.signal(txHash)
        }).add(to: linkBag)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            guard found == false else { return }
            guard policy != .ignore else {
                p.signal(nil)
                return
            }
            p.signal(BlockchainError.watchTimedOut)
        }
        return p
    }

    private func updateBalanceObservers(_ balance: Balance? = nil) {
        guard let balance = balance else { return }
        balanceObservers.values.forEach { block in
            block(balance)
        }
    }

    func addBalanceObserver(with block:@escaping (Balance) -> (), identifier: String? = nil) -> String {
        
        let observerIdentifier = identifier ?? UUID().uuidString
        balanceObservers[observerIdentifier] = block
        
        if let balance = lastBalance {
            block(balance)
        }
        
        if let ac = account {
            watchBalance(for: ac)
        }

        return observerIdentifier
    }

    func removeBalanceObserver(with identifier: String) {
        balanceObservers[identifier] = nil
        if balanceObservers.count == 0 {
            unwatchBalance()
        }
    }
    
    private func watchBalance(for account: KinAccountProtocol) {
        if balanceWatcher == nil {
            balanceWatcher = try? account.watchBalance(lastBalance?.amount)
            balanceWatcher?.emitter.on(next: { [weak self] amount in
                self?.lastBalance = Balance(amount: amount)
            }).add(to: linkBag)
        }
    }
    
    private func unwatchBalance() {
        balanceWatcher?.emitter.unlink()
        balanceWatcher = nil
    }
    
    func watchAccountCreation(timeout: TimeInterval = 30.0) -> Promise<Void> {
        
        let p = Promise<Void>()
        guard let account = account else {
            p.signal(KinEcosystemError.service(.notLoggedIn, nil))
            return p
        }
        
        var created = false
        
        do {
            try account.watchCreation()
            .then {
                created = true
                p.signal(())
            }.error { error in
                p.signal(error)
            }
        } catch {
            p.signal(error)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if created == false {
                p.signal(KinEcosystemError.service(.timeout, nil))
            }
        }

        return p
    }
    
    fileprivate func cleanup() {
        for version in [KinVersion.kinCore, KinVersion.kinSDK] {
            if let versionClient = migrationManager?.kinClient(version: version) {
                let count = versionClient.accounts.count
                if count > 10 {
                    logWarn("client \(version) holds more than 10 accounts (\(count)). This is slow for performance. Clearing up \(count - 10) accounts...")
                    for _ in 0..<(count - 10) {
                        try? versionClient.deleteAccount(at: 0)
                    }
                    logWarn("done.")
                }
            }
        }
    }
}



extension KinAccountProtocol {
    
    var kinExtraData: KinAccountExtraData {
        get {
            var result: KinAccountExtraData!
            synced(self) {
                // no data at all - means not onboarded
                guard let extraData = extra else {
                    result = KinAccountExtraData(user: nil, kinUserId: nil, environment: nil, onboarded: false, lastActive: Date.distantPast, backedUp: false)
                    return
                }
                // has valid data, return it
                if let accountData = try? JSONDecoder().decode(KinAccountExtraData.self, from: extraData) {
                    result = accountData
                    return
                }
                // has data, no format. This empty data object was used in previous versions to indicate an onboarded account, presumably single account
                result = KinAccountExtraData(user: nil, kinUserId: nil, environment: nil, onboarded: true, lastActive: Date.distantPast, backedUp: false)
            }
            return result
        }
        mutating set {
            synced(self) {
                extra = try? JSONEncoder().encode(newValue)
            }
        }
    }
    
}

extension KinAccountsProtocol {
    
    var debugInfo: String {
        get {
            var info = "total: \(count)\n\n"
            for i in 0..<count {
                if var anAccount = self[i] {
                    let data = anAccount.kinExtraData
                    info += """
                    account \(i)
                    \(anAccount.publicAddress)
                    ----------------------
                    user        : \(data.user ?? "nil")
                    ecosystem id: \(data.kinUserId ?? "nil")
                    environment : \(data.environment ?? "nil")
                    onboarded   : \(data.onboarded)
                    lastActive  : \(data.lastActive)
                    backedUp    : \(data.backedUp)
                    ----------------------
                    
                    """
                }
            }
            return info
        }
    }
    
}

extension Blockchain: KinMigrationManagerDelegate {
    public func kinMigrationManagerNeedsVersion(_ kinMigrationManager: KinMigrationManager) -> Promise<KinVersion> {
        guard let query = versionQuery else {
            fatalError("version query closure not set on blockchain object")
        }
        return query()
    }
    
    public func kinMigrationManagerDidStart(_ kinMigrationManager: KinMigrationManager) {
        logInfo("migration started...")
    }
    
    public func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, readyWith client: KinClientProtocol) {
        logInfo("migration manager is ready with client, version: \(kinMigrationManager.version?.rawValue ?? 0), number of accounts: \(client.accounts.count)")
        self.client = client
        if  let address = self.startingAddress,
            let addressAccount = client.accounts.makeIterator().first(where: { $0.publicAddress == address }) {
            do {
                try self.setActiveAccount(addressAccount)
                self.accountPromise.signal(addressAccount)
            } catch {
                self.accountPromise.signal(error)
            }
        } else {
            do {
                if let info = self.importedAccount {
                    guard let data = info.0.data(using: .utf8),
                        let accountData = try? JSONDecoder().decode(KinImportedAccountData.self, from: data) else {
                            throw KinEcosystemError.client(.accountReadFailed, nil)
                    }
                    var imported: KinAccountProtocol!
                    if let acc = client.accounts.makeIterator().first(where: { $0.publicAddress == accountData.pkey }) {
                        imported = acc
                    } else {
                        imported = try client.importAccount(info.0, passphrase: info.1)
                    }
                    try self.setActiveAccount(imported)
                    self.accountPromise.signal(imported)
                } else {
                    logInfo("no starting address provided or not found in persisted accounts - creating new")
                    let newAccount = try self.createNewAccount()
                    try self.setActiveAccount(newAccount)
                    self.accountPromise.signal(newAccount)
                }
            } catch {
                self.accountPromise.signal(error)
            }
        }
        self.importedAccount = nil
        self.startingAddress = nil
    }

    public func kinMigrationManager(_ kinMigrationManager: KinMigrationManager, error: Error) {
        if case KinMigrationError.invalidPublicAddress = error {
            kinMigrationManagerNeedsVersion(kinMigrationManager)
                .then { version in
                    let aClient = kinMigrationManager.kinClient(version: version)
                    self.client = aClient
                    if let info = self.importedAccount {
                        let imported = try aClient.importAccount(info.0, passphrase: info.1)
                        try self.setActiveAccount(imported)
                        self.accountPromise.signal(imported)
                    } else {
                        let newAccount = try self.createNewAccount()
                        try self.setActiveAccount(newAccount)
                        self.accountPromise.signal(newAccount)
                    }
            }.error { error in
                self.accountPromise.signal(error)
            }.finally {
                self.importedAccount = nil
                self.startingAddress = nil
            }
        } else {
            accountPromise.signal(error)
        }
    }
    
}

extension Blockchain: KinMigrationBIDelegate {
    public func kinMigrationMethodStarted() {
        Kin.track { try MigrationModuleStarted(publicAddress: startingAddress ?? "") }
    }
    
    public func kinMigrationCallbackStart() {
        
    }
    
    public func kinMigrationCallbackReady(reason: KinMigrationBIReadyReason, version: KinVersion) {
    }
    
    public func kinMigrationCallbackFailed(error: Error) {
        
    }
    
    public func kinMigrationVersionCheckStarted() {
    }
    
    public func kinMigrationVersionCheckSucceeded(version: KinVersion) {
        Kin.track { try MigrationBCVersionCheckSucceeded(blockchainVersion: version == .kinCore ? .the2 : .the3, publicAddress: account?.publicAddress ?? "") }
    }
    
    public func kinMigrationVersionCheckFailed(error: Error) {
        Kin.track { try MigrationBCVersionCheckFailed(blockchainVersion: migrationManager?.version == .kinSDK ? .the3 : .the2,
                                                      errorReason: error.localizedDescription,
                                                      publicAddress: account?.publicAddress ?? "") }
    }
    
    public func kinMigrationBurnStarted(publicAddress: String) {
    }
    
    public func kinMigrationBurnSucceeded(reason: KinMigrationBIBurnReason, publicAddress: String) {
    }
    
    public func kinMigrationBurnFailed(error: Error, publicAddress: String) {
    }
    
    public func kinMigrationRequestAccountMigrationStarted(publicAddress: String) {
        Kin.track { try MigrationAccountStarted(publicAddress: publicAddress) }
    }
    
    public func kinMigrationRequestAccountMigrationSucceeded(reason: KinMigrationBIMigrateReason, publicAddress: String) {
        Kin.track { try MigrationAccountCompleted(blockchainVersion: migrationManager?.version == .kinSDK ? .the3 : .the2, publicAddress: publicAddress) }

    }
    
    public func kinMigrationRequestAccountMigrationFailed(error: Error, publicAddress: String) {
        Kin.track { try MigrationAccountFailed(errorReason: error.localizedDescription, publicAddress: publicAddress) }
    }
}



