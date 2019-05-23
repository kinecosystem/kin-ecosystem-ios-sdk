//
//  SheetTransition.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

import UIKit

enum SheetTransitionCover: CGFloat {
    case half = 0.5
    case most = 0.75
    case all = 0.9
}

class PresentationController: UIPresentationController {
    private var calculatedFrameOfPresentedViewInContainerView = CGRect.zero
    private var shouldSetFrameWhenAccessingPresentedView = false
    
    override var presentedView: UIView? {
        if shouldSetFrameWhenAccessingPresentedView {
            super.presentedView?.frame = calculatedFrameOfPresentedViewInContainerView
        }
        
        return super.presentedView
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        shouldSetFrameWhenAccessingPresentedView = completed
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        shouldSetFrameWhenAccessingPresentedView = false
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        calculatedFrameOfPresentedViewInContainerView = frameOfPresentedViewInContainerView
    }
}

class SheetPresentationController: PresentationController {
    
    var cover: SheetTransitionCover = .half
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        let frame = containerView.bounds
        let frameHeight = frame.height * cover.rawValue
        return CGRect(x: 0.0, y: frame.height - frameHeight, width: frame.width, height: frameHeight)
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        guard let pView = presentedView else { return }
        pView.frame = frameOfPresentedViewInContainerView
        let viewMask = CAShapeLayer()
        viewMask.fillColor = UIColor.green.cgColor
        viewMask.frame = pView.bounds
        viewMask.path = UIBezierPath(roundedRect: pView.bounds,
                                     byRoundingCorners: [.topLeft, .topRight],
                                     cornerRadii: CGSize(width: 10.4, height: 10.4)).cgPath
        pView.layer.mask = viewMask
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        containerView?.backgroundColor = .clear
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.3)
                }, completion: nil)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.containerView?.backgroundColor = .clear
                }, completion: nil)
        }
    }
}


// TODO: remove
class SheetTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, CAAnimationDelegate {
    
    var isPresenting = true
    var transitionDuration: TimeInterval = 0.6
    var cover: SheetTransitionCover
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        return SheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    init(covering: SheetTransitionCover = .half) {
        self.cover = covering
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let blurEffectView: UIVisualEffectView

        let frame = transitionContext.containerView.bounds
        let frameHeight = frame.height * cover.rawValue
        
        let inFrame = CGRect(x: 0.0, y: frame.height - frameHeight, width: frame.width, height: frameHeight)
        let outFrame = CGRect(x: 0.0, y: frame.height, width: frame.width, height: frameHeight)
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
