//
//  AppDelegate.swift
//  EcosystemSampleApp
//
//  Created by Elazar Yifrach on 14/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import HockeySDK
import KinEcosystem

public func NSLocalizedString(_ key: String, tableName: String? = nil, bundle: Bundle = Bundle.main, value: String = "", comment: String) -> String {
    let fallbackLanguage = "en"
    guard let fallbackBundlePath = Bundle.main.path(forResource: fallbackLanguage, ofType: "lproj") else { return key }
    guard let fallbackBundle = Bundle(path: fallbackBundlePath) else { return key }
    let fallbackString = fallbackBundle.localizedString(forKey: key, value: comment, table: nil)
    return Bundle.main.localizedString(forKey: key, value: fallbackString, table: nil)
}

@UIApplicationMain
     class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BITHockeyManager.shared().configure(withIdentifier: "b652ffb01ad64bdeabe07a50b2a8d8d1")
        BITHockeyManager.shared().start()
        BITHockeyManager.shared().authenticator.authenticateInstallation()
        Kin.shared.setLogLevel(.verbose)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Kin.shared.canHandleURL(url) {
            Kin.shared.handleURL(url, options: options)
            return true
        }

        return false
    }
}

