//
//  RestoreNavigationController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class RestoreNavigationController: NavigationController {
    override init(keystoreProvider: KeystoreProvider) {
        super.init(keystoreProvider: keystoreProvider)
        
//        let introViewController = BackupIntroViewController()
//        introViewController.navigationItem.leftBarButtonItem = dismissBarButtonItem
//        viewControllers = [introViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Navigation

@available(iOS 9.0, *)
extension RestoreNavigationController {
    
}
