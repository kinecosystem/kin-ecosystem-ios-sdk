//
//  BackupNavigationController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class BackupNavigationController: NavigationController {
    override init(keystoreProvider: KeystoreProvider) {
        super.init(keystoreProvider: keystoreProvider)
        
        let introViewController = BackupIntroViewController()
        introViewController.navigationItem.leftBarButtonItem = dismissBarButtonItem
        introViewController.continueButton.addTarget(self, action: #selector(pushQRViewController), for: .touchUpInside)
        viewControllers = [introViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension BackupNavigationController {
    @objc private func pushPasswordViewController() {
        let passwordViewController = PasswordEntryViewController(nibName: "PasswordEntryViewController",
                                                                 bundle: Bundle.ecosystem)
        passwordViewController.delegate = self
        pushViewController(passwordViewController, animated: true)
    }
    
    @objc private func pushQRViewController() {
        let qrViewController = QRViewController(qrString: "exported keyphrase etc") // TODO:
        qrViewController.continueButton.addTarget(self, action: #selector(pushCompletedViewController), for: .touchUpInside)
        pushViewController(qrViewController, animated: true)
    }
    
    @objc private func pushCompletedViewController() {
        let completedViewController = BackupCompletedViewController()
        pushViewController(completedViewController, animated: true)
    }
}

// MARK: - Password

@available(iOS 9.0, *)
extension BackupNavigationController: PasswordEntryDelegate {
    func validatePasswordConformance(_ password: String) -> Bool {
        do {
            try keystoreProvider.validatePassword(password)
            return true
        }
        catch {
            return false
        }
    }
}
