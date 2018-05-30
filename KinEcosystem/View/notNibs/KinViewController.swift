//
//  KinViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 30/05/2018.
//

import UIKit

class KinViewController: UIViewController {
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}
