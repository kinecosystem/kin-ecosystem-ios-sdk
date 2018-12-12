//
//  Blockchain.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 11/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import KinCoreSDK
import StellarKit
import StellarErrors


struct KinAccountExtraData: Codable {
    var user: String?
    var environment: String?
    var onboarded: Bool
    var lastActive: Date
}

struct KinImportedAccountData: Decodable{
    let pkey: String
    let seed: String
    let salt: String
}

struct BlockchainProvider: ServiceProvider {
    let url: URL
    let networkId: KinCoreSDK.NetworkId
}

struct PaymentMemoIdentifier: CustomStringConvertible, Equatable, Hashable {
    var hashValue: Int {
        return description.hashValue
    }

    let version = "1"
    var appId: String
    var id: String

    var description: String {
        return "\(version)-\(appId)-\(id)"
    }

    static func ==(lhs: PaymentMemoIdentifier, rhs: PaymentMemoIdentifier) -> Bool {
        return lhs.description == rhs.description
    }
}

enum BlockchainError: Error {
    case watchNotStarted
    case watchTimedOut
}

@available(iOS 9.0, *)
class Blockchain {

    let client: KinClient
    fileprivate(set) var account: KinAccount!
    private let linkBag = LinkBag()
    private var paymentObservers = [PaymentMemoIdentifier : Observable<String>]()
    private var balanceObservers = [String : (Balance) -> ()]()
    private var paymentsWatcher: KinCoreSDK.PaymentWatch?
    private var balanceWatcher: KinCoreSDK.BalanceWatch?
    private let provider: BlockchainProvider
    private var creationWatch: StellarKit.PaymentWatch?
    private var creationLinkBag = LinkBag()
    private(set) var onboardInFlight = false
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
    private var onboardPromise = Promise<Void>()
    private var onboardLock: Int = 1
    private let userId: String
    private let environment: Environment
    fileprivate(set) var balanceObservable = Observable<Balance>()
    fileprivate(set) var lastBalance: Balance? {
        get {
            if  let data = UserDefaults.standard.data(forKey: KinPreferenceKey.lastBalance.rawValue),
                let cachedBalance = try? JSONDecoder().decode(Balance.self, from: data) {
                    return cachedBalance
            }
            return nil
        }
        set {
            let oldValue = lastBalance
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            if let balance = newValue {
                balanceObservable.next(balance)
            } else {
                UserDefaults.standard.set(nil, forKey: KinPreferenceKey.lastBalance.rawValue)
            }
            if newValue != oldValue {
                updateBalanceObservers()
            }
        }


    }
    fileprivate(set) var onboarded: Bool {
        get {
            var result: Bool!
            synced(onboardLock) {
                result = account.kinExtraData.onboarded
            }
            return result
        }
        set {
            isOnboarding = false
            guard newValue else {
                synced(onboardLock) {
                    var kinExtraData = account.kinExtraData
                    kinExtraData.onboarded = false
                    account.kinExtraData = kinExtraData
                }
                return
            }
            synced(onboardLock) {
                var kinExtraData = account.kinExtraData
                kinExtraData.onboarded = true
                kinExtraData.user = userId
                kinExtraData.lastActive = Date()
                account.kinExtraData = kinExtraData
            }
        }
    }

    init(environment: Environment, appId: String, userId: String) throws {
        guard let bURL = URL(string: environment.blockchainURL) else {
            throw KinEcosystemError.client(.badRequest, nil)
        }
        self.environment = environment
        self.userId = userId
        provider = BlockchainProvider(url: bURL, networkId: .custom(issuer: environment.kinIssuer, stellarNetworkId: .custom(environment.blockchainPassphrase)))
        let client = KinClient(provider: provider)
        self.client = client
    }
    
    func startAccount() throws {
        
        migrateAccountsIfNeeded()
        
        if Kin.shared.needsReset {
            lastBalance = nil
        }
        
        account = try getOrCreateAccount()
        _ = balance()
    }
    
    /* account finding pririty:
     
    from same users and environment,
        from onboarded
            last active
        else
            last active
        else
            create new
     else
        create new
     
    */
    func getOrCreateAccount() throws -> KinAccount {
        
        var accounts = [KinAccount]()
        
        // account iteration is currently broken on Accounts
        for i in 0..<client.accounts.count {
            if let anAccount = client.accounts[i] {
                accounts.append(anAccount)
            }
        }
        
        let candidateAccounts = accounts.filter { anAccount in
            return  anAccount.kinExtraData.user == userId &&
                    anAccount.kinExtraData.environment == environment.name
        }
        
        guard candidateAccounts.count > 0 else {
            return try createNewAccount()
        }
        
        let candidateOnboardedAccounts = candidateAccounts.filter ({ anAccount in
            return anAccount.kinExtraData.onboarded
        })
            
        if let candidateOnboardedAccount =  candidateOnboardedAccounts.sorted (by: { accountA, accountB in
                return accountA.kinExtraData.lastActive.compare(accountB.kinExtraData.lastActive) == .orderedAscending
        }).last {
            return candidateOnboardedAccount
        }
        
        if let candidateLastActiveAccount =  candidateAccounts.sorted (by: { accountA, accountB in
            return accountA.kinExtraData.lastActive.compare(accountB.kinExtraData.lastActive) == .orderedAscending
        }).last {
            return candidateLastActiveAccount
        }
        
        return try createNewAccount()
        
    }
    
    func accountForImporting(keystore: String, password: String) throws -> KinAccount {
        

        guard   let data = keystore.data(using: .utf8),
                let accountData = try? JSONDecoder().decode(KinImportedAccountData.self, from: data) else {
                    
                return try client.importAccount(keystore, passphrase: password)
        }
        
        guard validateAccountPassword(accountData, password: password) else {
            throw KinEcosystemError.blockchain(.invalidPassword, nil)
        }
        
        var accounts = [KinAccount]()
        
        // account iteration is currently broken on Accounts
        for i in 0..<client.accounts.count {
            if let anAccount = client.accounts[i] {
                accounts.append(anAccount)
            }
        }
        
        let candidateAccounts = accounts.filter { anAccount in
            return  anAccount.kinExtraData.user == userId &&
                    anAccount.kinExtraData.environment == environment.name &&
                    anAccount.publicAddress == accountData.pkey
        }
        
        guard candidateAccounts.count > 0 else {
            return try client.importAccount(keystore, passphrase: password)
        }
        
        let candidateOnboardedAccounts = candidateAccounts.filter ({ anAccount in
            return anAccount.kinExtraData.onboarded
        })
        
        if let candidateOnboardedAccount =  candidateOnboardedAccounts.sorted (by: { accountA, accountB in
            return accountA.kinExtraData.lastActive.compare(accountB.kinExtraData.lastActive) == .orderedAscending
        }).last {
            return candidateOnboardedAccount
        }
        
        if let candidateLastActiveAccount =  candidateAccounts.sorted (by: { accountA, accountB in
            return accountA.kinExtraData.lastActive.compare(accountB.kinExtraData.lastActive) == .orderedAscending
        }).last {
            return candidateLastActiveAccount
        }
        
        return try client.importAccount(keystore, passphrase: password)
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
    
    func setActiveAccount(_ anAccount: KinAccount) {
        account = anAccount
        var data = account.kinExtraData
        data.lastActive = Date()
        data.onboarded = true
        data.environment = environment.name
        data.user = userId
        account.kinExtraData = data
        _ = balance()
    }
    
    func createNewAccount() throws -> KinAccount {
        Kin.track { try StellarAccountCreationRequested() }
        let result = try client.addAccount()
        var kinExtraData = result.kinExtraData
        kinExtraData.user = userId
        kinExtraData.environment = environment.name
        result.kinExtraData = kinExtraData
        return result
    }
    
    func migrateAccountsIfNeeded() {
        
        let accounts = client.accounts
        let previousUser = UserDefaults.standard.string(forKey: KinPreferenceKey.lastSignedInUser.rawValue)
        let previousEnvironmentName = UserDefaults.standard.string(forKey: KinPreferenceKey.lastEnvironment.rawValue)
        
        if accounts.count == 1 {
            logVerbose("migration: has only one account. is candidate fot migration")
            guard accounts.first!.kinExtraData.user == nil else {
                logVerbose("migration: already migrated")
                return
            }
            var kinExtraData = accounts.first!.kinExtraData
            if Kin.shared.needsReset == false {
                logVerbose("migration: doesn't need reset and has one account, untagged - tag current user")
                kinExtraData.user = userId
                kinExtraData.environment = environment.name
            } else {
                logVerbose("migration: needs reset, tag the account so we can sometime get back to it")
                if let lastUser = previousUser {
                    kinExtraData.user = lastUser
                }
                if let lastEnvironment = previousEnvironmentName {
                    kinExtraData.environment = lastEnvironment
                }
            }
            accounts.first!.kinExtraData = kinExtraData
        }
        
    }
    
    func balance() -> Promise<Decimal> {
        let p = Promise<Decimal>()
        account.balance(completion: { [weak self] balance, error in
            if let error = error {
                p.signal(error)
            } else if let balance = balance {
                self?.lastBalance = Balance(amount: balance)
                p.signal(balance)
            } else {
                p.signal(KinError.internalInconsistency)
            }
        })

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
        
        balance()
            .then { _ in
                self.onboardPromise.signal(())
                self.onboarded = true
            }
            .error { (bError) in
                if case let KinError.balanceQueryFailed(error) = bError {
                    if let error = error as? StellarError {
                        switch error {
                        case .missingAccount:
                            self.watchAccountCreation(timeout: 15.0)
                                .then {
                                    self.account.activate()
                                }.then { _ in
                                    Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                    Kin.track { try WalletCreationSucceeded() }
                                    self.onboardPromise.signal(())
                                    self.onboarded = true
                                }.error { error in
                                    Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                    self.onboardPromise.signal(error)
                                    self.onboarded = false
                                }
                            
                        case .missingBalance:
                            self.account.activate().then { _ in
                                Kin.track { try StellarKinTrustlineSetupSucceeded() }
                                Kin.track { try WalletCreationSucceeded() }
                                self.onboardPromise.signal(())
                                self.onboarded = true
                            }.error { error in
                                Kin.track { try StellarKinTrustlineSetupFailed(errorReason: error.localizedDescription) }
                                self.onboardPromise.signal(error)
                                self.onboarded = false
                            }
                        default:
                            self.onboardPromise.signal(error)
                            self.onboarded = false
                        }
                    }
                    else {
                        self.onboardPromise.signal(bError)
                        self.onboarded = false
                    }
                }
                else {
                    self.onboardPromise.signal(bError)
                    self.onboarded = false
                }
        }

        return onboardPromise
    }


    func pay(to recipient: String, kin: Decimal, memo: String?) -> Promise<TransactionId> {
        return account.sendTransaction(to: recipient, kin: kin, memo: memo)
    }

    func startWatchingForNewPayments(with memo: PaymentMemoIdentifier) throws {
        guard paymentsWatcher == nil else {
            logInfo("payment watcher already started, added watch for \(memo)...")
            paymentObservers[memo] = Observable<String>()
            return
        }
        paymentsWatcher = try account.watchPayments(cursor: "now")
        paymentsWatcher?.emitter.on(next: { [weak self] paymentInfo in
            guard let metadata = paymentInfo.memoText else { return }
            guard let match = self?.paymentObservers.first(where: { (memoKey, _) -> Bool in
                memoKey.description == metadata
            })?.value else { return }
            logInfo("payment found in blockchain for \(metadata)...")
            match.next(paymentInfo.hash)
            match.finish()
        }).add(to: linkBag)
        logInfo("added watch for \(memo)...")
        paymentObservers[memo] = Observable<String>()
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

    func waitForNewPayment(with memo: PaymentMemoIdentifier, timeout: TimeInterval = 300.0) -> Promise<String> {
        let p = Promise<String>()
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
            if !found {
                p.signal(BlockchainError.watchTimedOut)
            }
        }
        return p
    }

    private func updateBalanceObservers() {
        guard let balance = lastBalance else { return }
        balanceObservers.values.forEach { block in
            block(balance)
        }
    }

    func addBalanceObserver(with block:@escaping (Balance) -> (), identifier: String? = nil) throws -> String {

        let observerIdentifier = identifier ?? UUID().uuidString
        balanceObservers[observerIdentifier] = block

        if balanceWatcher == nil {
            balanceWatcher = try account.watchBalance(lastBalance?.amount)
            balanceWatcher?.emitter.on(next: { [weak self] amount in
                self?.lastBalance = Balance(amount: amount)
            }).add(to: linkBag)
        }
        if let balance = lastBalance {
            block(balance)
        }

        return observerIdentifier
    }

    func removeBalanceObserver(with identifier: String) {
        balanceObservers[identifier] = nil
        if balanceObservers.count == 0 {
            balanceWatcher?.emitter.unlink()
            balanceWatcher = nil
        }
    }
    
    func watchAccountCreation(timeout: TimeInterval = 30.0) -> Promise<Void> {
        
        let p = Promise<Void>()
        let node = Stellar.Node(baseURL: provider.url, networkId: provider.networkId.stellarNetworkId)
        var created = false
        creationWatch = Stellar.paymentWatch(account: account.publicAddress, lastEventId: nil, node: node)
        
        creationWatch!.emitter.on(next: { [weak self] _ in
            created = true
            self?.creationWatch = nil
            self?.creationLinkBag = LinkBag()
            p.signal(())
        }).add(to: creationLinkBag)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [weak self] in
            if created == false {
                self?.creationWatch = nil
                self?.creationLinkBag = LinkBag()
                p.signal(KinEcosystemError.service(.timeout, nil))
            }
        }

        return p
    }
}

extension KinAccount {
    
    var kinExtraData: KinAccountExtraData {
        get {
            guard let extraData = extra else {
                let accountData = KinAccountExtraData(user: nil, environment: nil, onboarded: false, lastActive: Date.distantPast)
                extra = try? JSONEncoder().encode(accountData)
                return accountData
            }
            if let accountData = try? JSONDecoder().decode(KinAccountExtraData.self, from: extraData) {
                return accountData
            }
            let accountData = KinAccountExtraData(user: nil, environment: nil, onboarded: true, lastActive: Date())
            extra = try? JSONEncoder().encode(accountData)
            return accountData
        }
        set {
            extra = try? JSONEncoder().encode(newValue)
        }
    }
    
}

