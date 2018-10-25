//
//  BRViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class BRViewController: UIViewController {
    weak var lifeCycleDelegate: LifeCycleProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifeCycleDelegate?.viewController(self, willAppear: animated)
    }
}
