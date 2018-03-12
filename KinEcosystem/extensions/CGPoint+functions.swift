//
//  CGPoint+functions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 12/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

extension CGPoint {
    
    func distance(_ from: CGPoint) -> CGFloat {
        let xDist = self.x - from.x
        let yDist = self.y - from.y
        return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
    }
    
}
