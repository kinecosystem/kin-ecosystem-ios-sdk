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
    let recoveryManager = RecoveryManager(with: Kin.shared)
    
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
        
        // Push with existing stack
        let vc = UIViewController()
        vc.view.backgroundColor = .green
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true) {
            self.recoveryManager.start(.backup, pushedOnto: nc, events: { _ in

            }) { _ in

            }
        }
        
        // Push with empty stack
//        let nc = UINavigationController()
//        present(nc, animated: true) {
//            self.recoveryManager.start(.backup, pushedOnto: nc, events: { _ in
//
//            }) { _ in
//
//            }
//        }
        
        // Present
//        recoveryManager.start(.backup, presentedOn: self, events: { _ in
//
//        }) { _ in
//
//        }
    }
}

