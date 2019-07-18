//
//  UIView+More.swift
//  Maavak
//
//  Created by Alon Genosar on 7/27/17.
//  Copyright © 2017 Alon Genosar. All rights reserved.
//

import UIKit
import ObjectiveC
@IBDesignable
 class SuperUIView:UIView {
    @IBInspectable var angle:CGFloat = 0 {
        didSet {
           self.transform = CGAffineTransform(rotationAngle: 25/180*CGFloat.pi)
        }
    }
    override  func prepareForInterfaceBuilder() {
        self.transform = CGAffineTransform(rotationAngle: angle/180*CGFloat.pi)
    }
}
private extension Comparable {
    func clamp(_ lowerBound: Self, _ upperBound: Self) -> Self { return min(max(self, lowerBound), upperBound) }
}
extension UIView {
    var anchorPoint:CGPoint {
        set {
            var newPoint = CGPoint(x:bounds.size.width * newValue.x,y:bounds.size.height * newValue.y)
            var oldPoint = CGPoint(x:bounds.size.width * layer.anchorPoint.x,y:bounds.size.height * layer.anchorPoint.y)
            newPoint = newPoint.applying(transform);
            oldPoint = oldPoint.applying(transform);
            
            var position = layer.position
            position.x -= oldPoint.x
            position.x += newPoint.x
            
            position.y -= oldPoint.y
            position.y += newPoint.y
            
            layer.position = position;
            layer.anchorPoint = newValue;
        }
        get {
            return layer.anchorPoint
        }
    }
    
    var x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set (value){
            self.frame=CGRect(x: value, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }
    }
    
    var y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set(value) {
            self.frame=CGRect(x: self.frame.origin.x, y: value, width: self.frame.size.width, height: self.frame.size.height)
        }
    }
    
    var width: CGFloat {
        get {
            return self.frame.size.width
        }
        set (value){
            self.frame=CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: value, height: self.frame.size.height)
        }
    }
    
    var height: CGFloat {
        get { return frame.size.height }
        set(value) { frame=CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width, height:value)}
    }
    var origin: CGPoint {
        get { return frame.origin }
        set(value) { frame=CGRect(x: value.x, y:value.y, width: frame.width, height: frame.height) }
    }
    var bottom: CGFloat {
        get {
            return y+height
        }
        set (value){
            height = value - y
        }
    }
    
    var right: CGFloat {
        get {
            return x+width
        }
        set (value){
            width = value - x
        }
    }
    var boundsCenter: CGPoint {
        get { return CGPoint(x:width/2.0,y:height/2) }
        set { center = newValue }
    }
    var centerX: CGFloat {
        get {
            return center.x
        }
        set (value){
            center = CGPoint(x:value,y:center.y)
        }
    }
    
    var centerY: CGFloat {
        get {
            return center.y
        }
        set (value){
            center = CGPoint(x:center.x,y:value)
        }
    }
    var size: CGSize {
        get {
            return self.frame.size
        }
        set {
            self.frame = CGRect(x:x,y:y,width:newValue.width,height:newValue.height)
        }
    }
    func scale(by scale:CGFloat) {
        self.width *= scale
        self.height *= scale
    }
    func startBlinking(times: Int = -1,timeInterval:TimeInterval = 0.3) {
        let animateion: CABasicAnimation = CABasicAnimation(keyPath: "hidden")
        animateion.fromValue = 0
        animateion.toValue = 1
        animateion.duration = timeInterval
        animateion.autoreverses = true
        animateion.repeatCount = (times>0 ? Float(times) : Float(LLONG_MAX))
        self.layer.add(animateion, forKey: "hidden")
    }
    func stopBlinking(_ isHidden:Bool = false) {
        self.layer.removeAnimation(forKey: "hidden")
        self.layer.isHidden = isHidden
    }
    func removeAllConstraints() {
        
        removeConstraints(constraints)
        translatesAutoresizingMaskIntoConstraints = true
        
        if let superview = self.superview {
            let constraints = self.superview?.constraints.filter{
                $0.firstItem as? UIView == self || $0.secondItem as? UIView == self
                } ?? []
            
            superview.removeConstraints(constraints)
        }
    }
    func removeSubViews() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
    }
    func copyView<T: UIView>() -> T {
        let v =  NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
        v.frame = self.frame
        (v as UIView).layer.borderWidth = self.layer.borderWidth
        (v as UIView).layer.borderColor = self.layer.borderColor
        (v as UIView).layer.cornerRadius = self.layer.cornerRadius
        return v
    }
    
    /// Helper to get pre transform frame
    var originalFrame: CGRect {
        let currentTransform = transform
        transform = .identity
        let originalFrame = frame
        transform = currentTransform
        return originalFrame
    }
    
    /// Helper to get point offset from center
    func centerOffset(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x - center.x, y: point.y - center.y)
    }
    
    /// Helper to get point back relative to center
    func pointRelativeToCenter(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x + center.x, y: point.y + center.y)
    }
    /// Helper to get point relative to transformed coords
    func newPointInView(_ point: CGPoint) -> CGPoint {
        // get offset from center
        let offset = centerOffset(point)
        // get transformed point
        let transformedPoint = offset.applying(transform)
        // make relative to center
        return pointRelativeToCenter(transformedPoint)
    }
    var newTopLeft: CGPoint {
        return newPointInView(originalFrame.origin)
    }
    var newTopRight: CGPoint {
        var point = originalFrame.origin
        point.x += originalFrame.width
        return newPointInView(point)
    }
    var newBottomLeft: CGPoint {
        var point = originalFrame.origin
        point.y += originalFrame.height
        return newPointInView(point)
    }
    var newBottomRight: CGPoint {
        var point = originalFrame.origin
        point.x += originalFrame.width
        point.y += originalFrame.height
        return newPointInView(point)
    }
    convenience init(withSize size:CGFloat,color:UIColor) {
        self.init()
        self.size = CGSize(width:size,height:size)
        self.backgroundColor = color
    }
    convenience init(withRadius radius:CGFloat,color:UIColor) {
        self.init(withSize: radius*2, color: color)
        self.layer.cornerRadius = radius
    }
    public func setAssociatedData( key:inout String,value:Any) {
          objc_setAssociatedObject(self, &key, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    public func getAssociatedData(key:inout String) -> Any? {
        return objc_getAssociatedObject(self, &key)
    }
    func startRotating(duration: CFTimeInterval = 1, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        layer.removeAnimation(forKey:"transform.rotation.z")
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: .pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        self.layer.add(animation, forKey:"transform.rotation.z")
    }
    func stopRotating() {
        self.layer.removeAnimation(forKey: "transform.rotation.z")
        
    }
}
