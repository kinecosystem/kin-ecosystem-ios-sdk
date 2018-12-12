//
//  AccountSelectionTests.swift
//  KinEcosystemTests
//
//  Created by Elazar Yifrach on 05/12/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import XCTest
@testable import KinEcosystem
@testable import KinCoreSDK
import KinUtil

@available(iOS 9.0, *)
class AccountSelectionTests: XCTestCase {

    let environment: Environment = .beta
    var blockchain: Blockchain!
    let user = "1"
    override func setUp() {
        KeyStore.removeAll()
        createBlockchain()
    }

    override func tearDown() {
        blockchain = nil
    }
    
    func createBlockchain() {
        blockchain = try! Blockchain(environment: environment, appId: "test", userId: user)
    }
    
    func testSelectCorrectUser() {
        let account_1 = try! blockchain.createNewAccount()
        let account_2 = try! blockchain.createNewAccount()
        account_1.kinExtraData = KinAccountExtraData(user: user, environment: environment.name, onboarded: false, lastActive: Date())
        account_2.kinExtraData = KinAccountExtraData(user: "2", environment: environment.name, onboarded: true, lastActive: Date())
        try! blockchain.startAccount()
        XCTAssert(blockchain.account.publicAddress == account_1.publicAddress)
    }
    
    func testCreateIfNoUser() {
        let account_1 = try! blockchain.createNewAccount()
        let account_2 = try! blockchain.createNewAccount()
        account_1.kinExtraData = KinAccountExtraData(user: "2", environment: environment.name, onboarded: false, lastActive: Date())
        account_2.kinExtraData = KinAccountExtraData(user: "2", environment: environment.name, onboarded: true, lastActive: Date())
        try! blockchain.startAccount()
        XCTAssert(blockchain.account.publicAddress != account_1.publicAddress)
        XCTAssert(blockchain.account.publicAddress != account_2.publicAddress)
        XCTAssert(blockchain.client.accounts.count == 3)
    }
    
    func testSelectLastActiveAccount() {
        let account_1 = try! blockchain.createNewAccount()
        let account_2 = try! blockchain.createNewAccount()
        account_1.kinExtraData = KinAccountExtraData(user: user, environment: environment.name, onboarded: false, lastActive: Date())
        account_2.kinExtraData = KinAccountExtraData(user: user, environment: environment.name, onboarded: false, lastActive: Date())
        try! blockchain.startAccount()
        XCTAssert(blockchain.account.publicAddress == account_2.publicAddress)
    }
    
    func testSelectLastonboardedAccount() {
        let account_1 = try! blockchain.createNewAccount()
        let account_2 = try! blockchain.createNewAccount()
        let account_3 = try! blockchain.createNewAccount()
        let _ = try! blockchain.createNewAccount()
        account_1.kinExtraData = KinAccountExtraData(user: user, environment: environment.name, onboarded: true, lastActive: Date() + 10.0)
        account_2.kinExtraData = KinAccountExtraData(user: user, environment: environment.name, onboarded: true, lastActive: Date())
        account_3.kinExtraData = KinAccountExtraData(user: "2", environment: environment.name, onboarded: true, lastActive: Date() + 20.0)
        try! blockchain.startAccount()
        XCTAssert(blockchain.account.publicAddress == account_1.publicAddress)
    }

}
