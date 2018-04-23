//
//  UIView+extensions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 07/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 9.0, *)
extension UIView {
    func fillSuperview() {
        guard let parent = superview else { return }
        self.topAnchor.constraint(equalTo: parent.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: parent.bottomAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: parent.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: parent.trailingAnchor).isActive = true
    }
}

class KinGradientLayer : CAGradientLayer {
    override var colors: [Any]? {
        get {
            return [UIColor.kinAzureTwo.cgColor, UIColor.kinDeepSkyBlueTwo.cgColor]
        }
        set { super.colors = newValue }
    }
    
    override var startPoint: CGPoint {
        get {
            return CGPoint(x: 0, y: 1)
        }
        set { super.startPoint = newValue }
    }
    
    override var endPoint: CGPoint {
        get {
            return CGPoint(x: 0, y: 0)
        }
        set { super.endPoint = newValue }
    }
}

class KinGradientView : UIView {
    override open class var layerClass : Swift.AnyClass {
        get {
            return KinGradientLayer.self
        }
    }
}
