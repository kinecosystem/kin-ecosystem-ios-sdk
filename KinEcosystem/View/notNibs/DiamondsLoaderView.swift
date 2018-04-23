//
//  DiamondsLoaderView.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 12/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreGraphics

@available(iOS 9.0, *)
class CircularDashedLoader : CAShapeLayer {
    
    
    var lines = [CAShapeLayer]()
    var completion: (() -> ())?
    let dashes = 16
    let animationDuration = TimeInterval(1.2)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init() {
        super.init()
    }
    
    convenience init(size: CGSize, lineWidth: CGFloat = 2.0, lineColor: UIColor = .kinLightAqua) {
        self.init()
        
        let boundsRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        let lineRect = boundsRect.insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0)
        let radius = lineRect.width / 2.0
        lines = (0..<2).map({ i in
            let shape = CAShapeLayer()
            shape.bounds = boundsRect
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            shape.position = center
            shape.strokeStart = 0.0
            shape.strokeEnd = 0.0
            shape.path = UIBezierPath(roundedRect: lineRect, cornerRadius: radius).cgPath
            shape.lineWidth = lineWidth
            shape.strokeColor = lineColor.cgColor
            shape.lineCap = "round"
            shape.fillColor = UIColor.clear.cgColor
            if (i == 1) {
                let phase = (2.0 * Double.pi * Double(radius)) / (Double(dashes) * 2.0)
                shape.lineDashPattern = [NSNumber(floatLiteral: phase), NSNumber(floatLiteral: phase)]
            }
            return shape
        })
        lines.forEach { layer in
            addSublayer(layer)
        }
        
    }
    
    func startAnimating() {
        
        lines.forEach { line in
            line.removeAllAnimations()
        }
        
        let strokeEnd = Animations.animation(with: "strokeEnd", duration: animationDuration * 0.8, beginTime: 0.0, from: 0.0, to: 1.0)
        let strokeStart = Animations.animation(with: "strokeStart", duration: animationDuration * 0.8, beginTime: animationDuration * 0.2, from: 0.0, to: 1.0)
        
        let dashStrokeEnd = Animations.animation(with: "strokeEnd", duration: animationDuration * 0.8, beginTime: animationDuration * 0.2, from: 0.0, to: 1.0)
        
        let lineGroup = Animations.animationGroup(animations: [strokeStart, strokeEnd], duration: animationDuration)
        let dashGroup = Animations.animationGroup(animations: [dashStrokeEnd], duration: animationDuration)
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.duration = 4.0
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        rotationAnimation.repeatCount = .infinity
        lines.forEach { line in
            line.add(rotationAnimation, forKey: "rotation")
        }
        lines.first?.add(lineGroup, forKey: "stroke")
        lines.last?.add(dashGroup, forKey: "stroke")
    }
    
    func stopAnimating(completion: (() -> ())?) {
        
        self.completion = completion
        lines.forEach { line in
            line.removeAllAnimations()
        }
        lines.first?.strokeStart = 0.0
        lines.first?.strokeEnd = 0.0
        lines.last?.strokeStart = 0.0
        lines.last?.strokeEnd = 1.0
        
        let strokeStart = Animations.animation(with: "strokeStart", duration: animationDuration * 0.8, beginTime: animationDuration * 0.2, from: 0.0, to: 1.0)
        let strokeEnd = Animations.animation(with: "strokeEnd", duration: animationDuration * 0.8, beginTime: 0.0, from: 0.0, to: 1.0)
        let dashStrokeStart = Animations.animation(with: "strokeStart", duration: animationDuration * 0.8, beginTime: animationDuration * 0.2, from: 0.0, to: 1.0)
        
        
        let lineGroup = Animations.animationGroup(animations: [strokeStart, strokeEnd], duration: animationDuration)
        let dashGroup = Animations.animationGroup(animations: [dashStrokeStart], duration: animationDuration)
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.duration = 4.0
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        rotationAnimation.repeatCount = .infinity
        
        lines.forEach { line in
            line.add(rotationAnimation, forKey: "rotation")
        }
        
        lineGroup.setValue("linesAnimation", forKey: "animationName")
        lineGroup.delegate = self
        
        lines.first?.add(lineGroup, forKey: "stroke")
        lines.last?.add(dashGroup, forKey: "stroke")
        
        
    }
    
}

@available(iOS 9.0, *)
extension CircularDashedLoader : CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.removeAllAnimations()
        lines.forEach { line in
            line.strokeStart = 0.0
            line.strokeEnd = 0.0
            line.removeAllAnimations()
        }
        completion?()
    }
}

@available(iOS 9.0, *)
class DiamondsLoaderView : UIView {
    
    @IBInspectable
    var lineWidth: CGFloat = 2.0
    
    @IBInspectable
    var lineColor: UIColor = .kinLightAqua
    
    var timer: Timer!
    var imageView: UIImageView!
    var loader: CircularDashedLoader!
    var animated = false
    var imageIndex = 0
    let images = (1...3).map { UIImage.bundleImage("diamond\($0)") }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        commonInit()
    }
    
    deinit {
        timer.invalidate()
        timer = nil
    }
    
    func commonInit() {
        loader = CircularDashedLoader(size: self.bounds.size, lineWidth: lineWidth, lineColor: lineColor)
        self.layer.addSublayer(loader)
        let imageBounds = bounds.insetBy(dx: (bounds.width * 0.42) / 2.0, dy: (bounds.width * 0.42) / 2.0)
        imageView = UIImageView(frame: imageBounds)
        imageView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imageView.layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    @objc func timerFired(timer: Timer) {
        guard animated else { return }
        imageIndex = (imageIndex + 1) % 3
        let image = images[imageIndex]
        UIView.animate(withDuration: 0.08, delay: 0.0, options: [.curveEaseOut], animations: {
            self.imageView.layer.transform = CATransform3DMakeScale(0.86, 0.86, 1.0)
            self.imageView.alpha = 0.0
        }, completion: { _ in
            self.imageView.image = image
            UIView.animate(withDuration: 0.12, delay: 0.1, options: [.curveEaseOut], animations: {
                self.imageView.layer.transform = CATransform3DIdentity
                self.imageView.alpha = 1.0
            })
        })
    }
    
    func startAnimating() {
        guard animated == false else { return }
        animated = true
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 1.3, target: self, selector: #selector(timerFired(timer:)), userInfo: nil, repeats: true)
        timerFired(timer: timer)
        loader.startAnimating()
    }
    
    func stopAnimating(completion: (() -> ())?) {
        guard animated else {
            completion?()
            return
        }
        animated = false
        loader.stopAnimating {
            completion?()
        }
    }
}
