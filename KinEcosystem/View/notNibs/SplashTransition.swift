//
//  SplashTransition.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 12/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import UIKit

class SplashTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    weak var animatedView: UIView?
    var startFrame = CGRect()
    var transitionDuration: TimeInterval = 0.5
    weak var context: UIViewControllerContextTransitioning?

    convenience public init(animatedView: UIView) {
        self.init()
        self.animatedView = animatedView
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let animatedView = animatedView, let superview = animatedView.superview {
            self.startFrame = superview.convert(animatedView.frame, to: nil)
        }
        
        let startFrame = transitionContext.containerView.superview?.convert(self.startFrame, to: transitionContext.containerView) ?? self.startFrame
        
        context = transitionContext
        let mask = CAShapeLayer()
        mask.frame = transitionContext.containerView.bounds
        mask.path = UIBezierPath(roundedRect: startFrame, cornerRadius: startFrame.width / 2.0).cgPath
        mask.fillColor = UIColor.green.cgColor
        
        let presentedController = transitionContext.viewController(forKey: .to)!
        let frame = transitionContext.containerView.bounds
        presentedController.view.layer.mask = mask
        presentedController.view.frame = frame
        transitionContext.containerView.addSubview(presentedController.view)
        
        let radius = CGPoint.zero.distance(CGPoint(x: frame.width, y: frame.height)) / CGFloat(2.0)
        let endFrame = CGRect(x: frame.midX - radius, y: frame.midY - radius, width: 2.0 * radius, height: 2.0 * radius)
        let finalPath = UIBezierPath(roundedRect: endFrame, cornerRadius: endFrame.width / 2.0).cgPath
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.toValue = finalPath
        animation.duration = 0.3
        animation.fillMode = kCAFillModeBoth
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.delegate = self
        mask.add(animation, forKey: "growAnimation")
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard   let context = context,
                let presentedController = context.viewController(forKey: .to) else { return }
        presentedController.view.layer.mask = nil
        context.completeTransition(!context.transitionWasCancelled)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
}
