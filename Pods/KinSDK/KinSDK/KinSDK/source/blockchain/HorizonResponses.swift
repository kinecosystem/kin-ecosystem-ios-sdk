//
//  HorizonResponses.swift
//  StellarKit
//
//  Created by Kin Foundation.
//  Copyright © 2018 Kin Foundation. All rights reserved.
//

import Foundation

struct HorizonError: Decodable {
    let type: URL
    let title: String
    let status: Int
    let detail: String
    let instance: String?
    let extras: Extras?

    struct Extras: Decodable {
        let resultXDR: String

        enum CodingKeys: String, CodingKey {
            case resultXDR = "result_xdr"
        }
    }
}

public struct NetworkParameters: Decodable {
    private let _links: Links
    private let _embedded: [String: [LedgerResponse]]

    public var baseFee: Stroop {
        return _embedded["records"]!.first!.base_fee_in_stroops
    }
}

public struct AccountDetails: Decodable, CustomStringConvertible {
    public let id: String
    public let accountId: String
    public let sequence: String
    public let balances: [Balance]

    public var seqNum: UInt64 {
        return UInt64(sequence) ?? 0
    }

    public struct Balance: Decodable, CustomStringConvertible {
        public let balance: String
        public let assetType: String

        public var balanceNum: Kin {
            return Decimal(string: balance) ?? Decimal()
        }

        public var asset: Asset {
            return .native
        }

        public var description: String {
            return "balance: \(balance)"
        }

        enum CodingKeys: String, CodingKey {
            case balance
            case assetType = "asset_type"
        }
    }

    public var description: String {
        return """
        id: \(id)
        publicKey: \(accountId)
        sequence: \(sequence)
        balances: \(balances)
        """
    }

    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case sequence
        case balances
    }
}

struct TransactionResponse: Decodable {
    let hash: String
    let resultXDR: String

    enum CodingKeys: String, CodingKey {
        case hash
        case resultXDR = "result_xdr"
    }
}

struct LedgerResponse: Decodable {
    let _links: Links?
    let id: String
    let hash: String
    let base_fee_in_stroops: Stroop
    let base_reserve_in_stroops: Stroop
    let max_tx_set_size: Int
}

struct Links: Decodable {
    let `self`: Link

    let next: Link?
    let prev: Link?

    let transactions: Link?
    let operations: Link?
    let payments: Link?
    let effects: Link?
}

struct Link: Decodable {
    let href: String
    let templated: Bool?
}
