//
//  UINavigationBar+Appearance.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

extension UINavigationBar {
    func removeBackground() {
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
    }
    
    func restoreBackground(backgroundImage: UIImage?, shadowImage: UIImage?) {
        setBackgroundImage(backgroundImage, for: .default)
        self.shadowImage = shadowImage
    }
}
