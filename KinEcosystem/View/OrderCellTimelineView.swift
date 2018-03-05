//
//  OrderCellTimelineView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 05/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

class OrderCellTimelineView: UIView {
    
    var last: Bool? {
        didSet {
            setNeedsDisplay()
        }
    }
    var color: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let last = last, let color = color else {
            super.draw(rect)
            return
        }
        let top = CGPoint(x: rect.midX, y: 0.0)
        let mid = CGPoint(x: rect.midX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.height)
        let line = UIBezierPath()
        
        line.lineWidth = 1.0
        line.setLineDash([5.0, 4.0], count: 2, phase: 0)
        line.lineCapStyle = .round
        line.move(to: top)
        
        if last == false {
            line.addLine(to: bottom)
        } else {
            line.addLine(to: mid)
        }
        UIColor.kinLightBlueGrey.setStroke()
        line.stroke()
        
        UIColor.white.setFill()
        let circleFrame = UIBezierPath(ovalIn: CGRect(x: mid.x - 6.0, y: mid.y - 6.0, width: 12.0, height: 12.0))
        circleFrame.lineWidth = 1.0
        circleFrame.fill()
        circleFrame.stroke()
        
        color.setFill()
        let circle = UIBezierPath(ovalIn: CGRect(x: mid.x - 4.0, y: mid.y - 4.0, width: 8.0, height: 8.0))
        circle.lineWidth = 0.0
        circle.fill()
        
    }
    
}
