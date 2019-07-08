//
//  KinDotsActivityIndicator.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 03/06/2019.
//

import UIKit

class KinDotsActivityIndicator: UIView {
    
    private var dotLayers = [CAShapeLayer]()
    private var dotsScale = 2.0
    
    let dotsCount: Int = 3
    let dotsRadius: CGFloat = 4
    let dotsSpacing: CGFloat = 10
    
    override var tintColor: UIColor! {
        didSet {
            for layer in dotLayers {
                layer.fillColor = tintColor.cgColor
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupLayers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupLayers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let center = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        let even = (dotsCount % 2 == 0)
        let middle: Int = dotsCount/2
        for (index, layer) in dotLayers.enumerated() {
            let x = center.x+CGFloat(index-middle)*((dotsRadius*2)+dotsSpacing)+(even ? (dotsRadius+(dotsSpacing/2)):  0)
            layer.position = CGPoint(x: x, y: center.y)
        }
        startAnimating()
    }
    
    func startAnimating() {
        var offset: TimeInterval = 0.0
        dotLayers.forEach {
            $0.removeAllAnimations()
            $0.add(scaleAnimation(offset), forKey: "scaleAnim")
            offset = offset + 0.2
        }
    }
    
    func stopAnimating() {
        dotLayers.forEach { $0.removeAllAnimations() }
    }
    
    private func dotLayer() -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: dotsRadius*2.0, height: dotsRadius*2.0))
        layer.path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: dotsRadius).cgPath
        layer.fillColor = tintColor.cgColor
        return layer
    }
    
    private func setupLayers() {
        for _ in 0..<dotsCount {
            let layer = dotLayer()
            self.dotLayers.append(layer)
            self.layer.addSublayer(layer)
            layer.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: dotsRadius*2.0, height: dotsRadius*2.0))
            layer.path = UIBezierPath(roundedRect: layer.bounds, cornerRadius: dotsRadius).cgPath
        }
    }
    
    private func scaleAnimation(_ after: TimeInterval = 0) -> CAAnimationGroup {
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.beginTime = after
        scaleUp.fromValue = 1
        scaleUp.toValue = dotsScale
        scaleUp.duration = 0.16
        scaleUp.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.beginTime = after+scaleUp.duration
        scaleDown.fromValue = dotsScale
        scaleDown.toValue = 1.0
        scaleDown.duration = 0.1
        scaleDown.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        
        let group = CAAnimationGroup()
        group.animations = [scaleUp, scaleDown]
        group.repeatCount = Float.infinity
        
        let sum = CGFloat(dotsCount)*0.3+CGFloat(0.4)
        group.duration = CFTimeInterval(sum)
        
        return group
    }
}
