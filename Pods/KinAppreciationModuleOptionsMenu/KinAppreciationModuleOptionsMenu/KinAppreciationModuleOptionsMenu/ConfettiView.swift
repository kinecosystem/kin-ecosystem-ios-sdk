//
//  ConfettiView.swift
//  KinAppreciationModuleOptionsMenu
//
//  Created by Corey Werner on 20/06/2019.
//  Copyright © 2019 Kin Foundation. All rights reserved.
//

import UIKit

protocol ConfettiViewDelegate: NSObjectProtocol {
    func confettiViewDidComplete(_ confettiView: ConfettiView)
}

class ConfettiView: UIView {
    weak var delegate: ConfettiViewDelegate?

    var count = 1

    let images: [UIImage?] = {
        var images: [UIImage?] = []
        let names = ["ConfettiCircle", "ConfettiRectangle", "ConfettiSquiggle"]

        for name in names {
            let image = UIImage(named: name, in: .appreciation, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            images.append(image)
        }

        return images
    }()

    private var animator: UIDynamicAnimator!

    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        animator = UIDynamicAnimator(referenceView: self)
        animator.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        animator.delegate = nil
    }

    // MARK: Layout

    private func layoutConfetti(iterator: (_ imageView: UIImageView) -> ()) {
        // Use predefined size to prevent vast difference in magnitude speed.
        let imageSize = CGSize(width: 15, height: 15)
        let insetRect = bounds.insetBy(dx: imageSize.width / 2, dy: imageSize.height / 2)

        for i in 0..<count {
            let x = CGFloat(arc4random_uniform(UInt32(insetRect.width))) + insetRect.origin.x
            let y = CGFloat(arc4random_uniform(UInt32(insetRect.height))) + insetRect.origin.y

            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            imageView.center = CGPoint(x: x, y: y)
            imageView.image = images[i % images.count]
            imageView.contentMode = .center
            self.addSubview(imageView)

            let color = Colors(rawValue: i % Colors.count)?.color

            if let _ = imageView.image {
                imageView.tintColor = color
            }
            else {
                imageView.backgroundColor = color
            }

            iterator(imageView)
        }
    }
}

// MARK: - Animations

extension ConfettiView {
    func explodeAnimation() {
        layoutConfetti(iterator: { imageView in
            let precision: CGFloat = 1000
            let maxAngle = (2 * CGFloat.pi) * precision
            let angle = CGFloat(arc4random_uniform(UInt32(maxAngle))) / precision

            let maxSpin: CGFloat = 3
            let spin = CGFloat(arc4random_uniform(UInt32(maxSpin * 2 + 1))) - maxSpin

            let pushBehavior = UIPushBehavior(items: [imageView], mode: .instantaneous)
            pushBehavior.setAngle(angle, magnitude: 0.02)
            pushBehavior.setTargetOffsetFromCenter(UIOffset(horizontal: spin, vertical: 0), for: imageView)
            pushBehavior.action = self.completeExplodeAnimation(pushBehavior, imageView)

            self.animator.addBehavior(pushBehavior)
        })
    }

    private func completeExplodeAnimation(_ pushBehavior: UIPushBehavior, _ imageView: UIImageView) -> (() -> Void) {
        let inset = min(bounds.width, bounds.height)
        let thresholdRect = imageView.frame.insetBy(dx: -inset, dy: -inset)

        return {
            guard !thresholdRect.contains(imageView.center), imageView.tag == 0 else {
                return
            }

            imageView.tag = 1

            UIView.animate(withDuration: 0.3, animations: {
                imageView.alpha = 0
            }, completion: { _ in
                pushBehavior.removeItem(imageView)
                imageView.removeFromSuperview()
            })
        }
    }
}

// MARK: - Dynamic Animator

extension ConfettiView: UIDynamicAnimatorDelegate {
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        self.delegate?.confettiViewDidComplete(self)
    }
}

// MARK: - Colors

extension ConfettiView {
    enum Colors: Int {
        case blue
        case magenta
        case orange
        case pink
        case violet
        case yellow
    }
}

extension ConfettiView.Colors {
    static let count = 6

    var color: UIColor {
        switch self {
        case .blue:
            return UIColor(red: 147/255, green: 107/255, blue: 251/255, alpha: 1)
        case .magenta:
            return UIColor(red: 219/255, green: 74/255, blue: 124/255, alpha: 1)
        case .orange:
            return UIColor(red: 255/255, green: 135/255, blue: 49/255, alpha: 1)
        case .pink:
            return UIColor(red: 225/255, green: 131/255, blue: 233/255, alpha: 1)
        case .violet:
            return UIColor(red: 175/255, green: 65/255, blue: 186/255, alpha: 1)
        case .yellow:
            return UIColor(red: 255/255, green: 214/255, blue: 84/255, alpha: 1)
        }
    }
}
