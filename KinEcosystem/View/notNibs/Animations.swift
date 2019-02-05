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
                   curve: CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.duration = duration
        animation.fromValue = from
        animation.toValue = to
        animation.beginTime = beginTime
        animation.timingFunction = curve
        animation.fillMode = CAMediaTimingFillMode.forwards
        return animation
    }
    
    static func animationGroup(animations: [CABasicAnimation], duration: TimeInterval) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = duration
        group.repeatCount = 1
        group.isRemovedOnCompletion = false
        group.fillMode = CAMediaTimingFillMode.forwards
        group.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        return group
    }
}
