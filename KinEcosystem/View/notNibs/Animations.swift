//
//  Animations.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 27/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

class Animations {
    static func animation(with keyPath: String,
                   duration: TimeInterval,
                   beginTime: TimeInterval,
                   from: Any,
                   to: Any,
                   curve: CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        animation.beginTime = beginTime
        animation.timingFunction = curve
        animation.fillMode = kCAFillModeForwards
        return animation
    }
    
    static func animationGroup(animations: [CABasicAnimation], duration: TimeInterval) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        group.repeatCount = 1
        group.isRemovedOnCompletion = false
        group.fillMode = kCAFillModeForwards
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return group
    }
}
