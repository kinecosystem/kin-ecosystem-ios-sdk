//
//  KinButton.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/05/2019.
//

import Foundation
import KinMigrationModule

class KinButton: UIButton {
    let themeLinkBag = LinkBag()

    var enabledColor: UIColor = .clear
    var disabledColor: UIColor = .clear
    var highlightedColor: UIColor = .clear

    private var transitionToConfirmedCompletion: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        tintColor = .white
        layer.masksToBounds = true
        setupTheming()
        titleLabel?.font = Font(name: "Sailec-Medium", size: 16)
        setTitleColor(UIColor.KinNewUi.white, for: .normal)
        setTitleColor(UIColor.KinNewUi.brownGray, for: .disabled)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 5.0
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 50
        return size
    }
    
    override var isEnabled: Bool {
        didSet {
            self.backgroundColor = isEnabled ? enabledColor : disabledColor
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? highlightedColor : enabledColor
        }
    }

    func transitionToConfirmed(completion: (() -> Void)? = nil) {
        let shape = CAShapeLayer()
        shape.frame = bounds
        shape.fillColor = enabledColor.cgColor
        shape.strokeColor = UIColor.clear.cgColor
        shape.path = UIBezierPath(roundedRect: shape.bounds, cornerRadius: shape.bounds.height / 2.0).cgPath
        setBackgroundImage(nil, for: .normal)
        setTitleColor(.clear, for: .normal)
        isEnabled = false
        backgroundColor = .clear
        layer.addSublayer(shape)
        let vShape = CAShapeLayer()
        vShape.bounds = CGRect(x: 0.0, y: 0.0, width: 19.0, height: 15.0)
        vShape.position = shape.position
        vShape.strokeColor = UIColor.kinWhite.cgColor
        vShape.lineWidth = 2.0
        let vPath = UIBezierPath()
        vPath.move(to: CGPoint(x: 0.0, y: 7.0))
        vPath.addLine(to: CGPoint(x: 7.0, y: 15.0))
        vPath.addLine(to: CGPoint(x: 19.0, y: 0.0))
        vShape.path = vPath.cgPath
        vShape.fillColor = UIColor.clear.cgColor
        vShape.strokeStart = 0.0
        vShape.strokeEnd = 0.0
        layer.addSublayer(vShape)
        let duration = 0.64

        let pathAnimation = Animations.animation(with: "path", duration: duration * 0.25, beginTime: 0.0, from: shape.path!, to: UIBezierPath(roundedRect: shape.bounds.insetBy(dx: (shape.bounds.width / 2.0) - 25.0, dy: 0.0), cornerRadius: shape.bounds.height / 2.0).cgPath)
        let vPathAnimation = Animations.animation(with: "strokeEnd", duration: duration * 0.45, beginTime: duration * 0.55, from: 0.0, to: 1.0)
        let shapeGroup = Animations.animationGroup(animations: [pathAnimation], duration: duration)
        let vPathGroup = Animations.animationGroup(animations: [vPathAnimation], duration: duration)
        vPathGroup.delegate = self
        shape.add(shapeGroup, forKey: "shrink")
        vShape.add(vPathGroup, forKey: "vStroke")

        transitionToConfirmedCompletion = completion
    }
}

extension KinButton: Themed {
    func applyTheme(_ theme: Theme) {
        enabledColor = theme.actionButtonEnabledColor
        disabledColor = theme.actionButtonDisabledColor
        highlightedColor = theme.actionButtonHighlightedColor

        backgroundColor = isEnabled ? enabledColor : disabledColor
    }
}

extension KinButton: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        transitionToConfirmedCompletion?()
        transitionToConfirmedCompletion = nil
    }
}
