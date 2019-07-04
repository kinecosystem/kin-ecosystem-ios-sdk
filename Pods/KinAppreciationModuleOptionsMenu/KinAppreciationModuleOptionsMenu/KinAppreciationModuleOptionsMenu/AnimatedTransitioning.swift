//
//  AnimatedTransitioning.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 19/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

class AnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    let presenting: Bool

    init(presenting: Bool) {
        self.presenting = presenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let viewControllerKey: UITransitionContextViewControllerKey = presenting ? .to : .from

        guard let viewController = transitionContext.viewController(forKey: viewControllerKey) else {
            return
        }

        let startingFrane = initialFrame(viewController)

        if presenting {
            viewController.view.frame = startingFrane
            transitionContext.containerView.addSubview(viewController.view)
        }

        let options: UIView.AnimationOptions = presenting ? .curveEaseOut : .curveEaseIn
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
            if self!.presenting {
                viewController.view.frame = transitionContext.finalFrame(for: viewController)
            }
            else {
                viewController.view.frame = startingFrane
            }
        }) { completed in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func initialFrame(_ viewController: UIViewController) -> CGRect {
        var frame = viewController.view.frame

        if let presentationController = viewController.presentationController as? PresentationController {
            frame = presentationController.frameOfDismissedViewInContainerView
        }

        return frame
    }
}
