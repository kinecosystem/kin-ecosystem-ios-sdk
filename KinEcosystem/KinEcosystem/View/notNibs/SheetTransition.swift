//
//  SheetTransition.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

import UIKit

class SheetTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    var isPresenting = true
    var transitionDuration: TimeInterval = 0.6
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let blurEffectView: UIVisualEffectView

        let frame = transitionContext.containerView.bounds
        
        let recommandedHeight: CGFloat = max(335.0, frame.height / 2.0)
        
        let inFrame = CGRect(x: 0.0, y: frame.height - recommandedHeight, width: frame.width, height: recommandedHeight)
        let outFrame = CGRect(x: 0.0, y: frame.height, width: frame.width, height: recommandedHeight)
        let spendController = transitionContext.viewController(forKey: isPresenting ? .to : .from)!
        let presentor = transitionContext.viewController(forKey: isPresenting ? .from : .to)!
        spendController.view.frame = isPresenting ? outFrame : inFrame
       
        
        if isPresenting {
            let blurEffect = UIBlurEffect(style: .dark)
            blurEffectView = UIVisualEffectView(effect: blurEffect)
            blurEffectView.tag = 26163
        } else {
            blurEffectView = presentor.view.viewWithTag(26163)! as! UIVisualEffectView
        }
        blurEffectView.frame = frame
        blurEffectView.alpha = isPresenting ? 0.0 : 1.0
        if isPresenting {
            presentor.view.addSubview(blurEffectView)
            transitionContext.containerView.addSubview(spendController.view)
        }
        let p = isPresenting
        UIView.animate(withDuration: transitionDuration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 3.9, options: [], animations: {
            blurEffectView.alpha = p ? 1.0 : 0.0
            spendController.view.frame = p ? inFrame : outFrame
        }, completion: { finished in
            if p == false {
                blurEffectView.removeFromSuperview()
                spendController.view.removeFromSuperview()
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })

    }
    
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
}
