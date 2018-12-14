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
    
    func restoreBackground(backgroundImages: [UIBarMetrics: UIImage?]?, shadowImage: UIImage?) {
        if let backgroundImages = backgroundImages {
            for (barMetric, backgroundImage) in backgroundImages {
                setBackgroundImage(backgroundImage, for: barMetric)
            }
        }
        
        self.shadowImage = shadowImage
    }
}
