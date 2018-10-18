//
//  ViewController.swift
//  KinEcosystemTestsHost
//
//  Created by Elazar Yifrach on 12/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import KinEcosystem

class ViewController: UIViewController {
    let recoverManager = RecoveryManager(with: Kin.shared)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        recoverManager.start(.backup, from: self, events: { _ in
            
        }) { _ in
            
        }
    }
}

