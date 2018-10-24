//
//  FlowController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 23/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class FlowController {
    let keystoreProvider: KeystoreProvider
    let navigationController: UINavigationController
    
    init(keystoreProvider: KeystoreProvider, navigationController: UINavigationController) {
        self.keystoreProvider = keystoreProvider
        self.navigationController = navigationController
    }
    
    var entryViewController: UIViewController {
        fatalError("entryViewController() has not been implemented")
    }
}
