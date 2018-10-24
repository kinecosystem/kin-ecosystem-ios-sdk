//
//  NavigationController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 18/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        delegate = self
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.tintColor = topViewController?.preferredStatusBarStyle.color
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
}

extension NavigationController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationController.navigationBar.tintColor = viewController.preferredStatusBarStyle.color
    }
}
