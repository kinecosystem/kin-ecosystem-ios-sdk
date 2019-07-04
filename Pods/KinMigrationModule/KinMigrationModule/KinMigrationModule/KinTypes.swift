//
//  KinTypes.swift
//  multi
//
//  Created by Corey Werner on 04/12/2018.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import KinSDK
import KinCoreSDK
import KinUtil

public typealias Kin = KinSDK.Kin
public typealias Stroop = KinSDK.Stroop
public typealias AppId = KinSDK.AppId
public typealias Node = KinSDK.Stellar.Node
public typealias TransactionId = KinSDK.TransactionId
public typealias TransactionEnvelope = KinSDK.TransactionEnvelope
public typealias WhitelistEnvelope = KinSDK.WhitelistEnvelope
public typealias XDREncoder = KinSDK.XDREncoder
public typealias XDRDecoder = KinSDK.XDRDecoder
public typealias KeyUtils = KinSDK.KeyUtils
public typealias KeyUtilsError = KinSDK.KeyUtilsError
public typealias LinkBag = KinSDK.LinkBag
public typealias Promise = KinSDK.Promise
public typealias Observable<T> = KinSDK.Observable<T>

typealias KinSDKMemo = KinSDK.Memo

public enum KinVersion: Int, Codable {
    /**
     Kin Core version

     Also known as Kin 2.
     */
    case kinCore = 2

    /**
     Kin SDK version

     Also known as Kin 3.
     */
    case kinSDK = 3
}

public protocol KinClientProtocol {
    var url: URL { get }
    var network: Network { get }
    var accounts: KinAccountsProtocol { get }
    func addAccount() throws -> KinAccountProtocol
    func deleteAccount(at index: Int) throws
    func importAccount(_ jsonString: String, passphrase: String) throws -> KinAccountProtocol
    func deleteKeystore()
    func minFee() -> Promise<Stroop>
}

public protocol KinAccountsProtocol {
    subscript(_ index: Int) -> KinAccountProtocol? { get }
    var count: Int { get }
    var first: KinAccountProtocol? { get }
    var last: KinAccountProtocol? { get }
    var startIndex: Int { get }
    var endIndex: Int { get }
    func makeIterator() -> AnyIterator<KinAccountProtocol>
}

public protocol KinAccountProtocol {
    var publicAddress: String { get }
    var extra: Data? { get set }
    func activate() -> Promise<Void> // KinCore only
    func status() -> Promise<AccountStatus>
    func balance() -> Promise<Kin>
    func burn() -> Promise<String?> // KinCore only
    func sendTransaction(to recipient: String, kin: Kin, memo: String?, fee: Stroop, whitelist: @escaping WhitelistClosure) -> Promise<TransactionId>
    func export(passphrase: String) throws -> String
    func watchCreation() throws -> Promise<Void>
    func watchBalance(_ balance: Kin?) throws -> BalanceWatchProtocol
    func watchPayments(cursor: String?) throws -> PaymentWatchProtocol
}

public typealias WhitelistClosure = (TransactionEnvelope) -> Promise<TransactionEnvelope?>

public enum AccountStatus: Int {
    case notCreated
    case created
    case notActivated // KinCore only
}

public protocol BalanceWatchProtocol {
    var emitter: StatefulObserver<Kin> { get }
}

public protocol PaymentWatchProtocol {
    var emitter: Observable<PaymentInfoProtocol> { get }
    var cursor: String? { get }
}

public protocol PaymentInfoProtocol {
    var createdAt: Date { get }
    var credit: Bool { get }
    var debit: Bool { get }
    var source: String { get }
    var hash: String { get }
    var amount: Kin { get }
    var destination: String { get }
    var memoText: String? { get }
    var memoData: Data? { get }
}

internal let kinCoreAssetUnitDivisor: UInt64 = 10_000_000
internal let kinSDKAssetUnitDivisor: UInt64 = 100_000
