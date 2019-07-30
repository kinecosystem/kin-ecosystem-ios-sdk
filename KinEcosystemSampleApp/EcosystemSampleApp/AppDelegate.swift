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

@UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BITHockeyManager.shared().configure(withIdentifier: "90ae7adeee724658b6b9ec5448a09fb8")
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
