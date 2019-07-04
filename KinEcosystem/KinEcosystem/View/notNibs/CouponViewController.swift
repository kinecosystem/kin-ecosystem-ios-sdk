//
//  CouponViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 28/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import SafariServices



@available(iOS 9.0, *)
class CouponViewController: UIViewController, UITextViewDelegate {

    struct BIData {
        var offerId: String
        var orderId: String
        var amount: Double
        var trigger: KBITypes.RedeemTrigger
    }
    
    var viewModel: CouponViewModel!
    var biData: BIData!
    @IBOutlet weak var couponImageView: UIImageView!
    @IBOutlet weak var couponTitle: UILabel!
    @IBOutlet weak var couponDescription: UITextView!
    @IBOutlet weak var couponCode: UILabel!
    @IBOutlet weak var copyCodeButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.image.then(on: .main) { [weak self] result in
            self?.couponImageView.image = result.image
        }
        couponDescription.textContainer.maximumNumberOfLines = 1
        couponDescription.textContainer.lineBreakMode = .byTruncatingTail
        couponDescription.textContainerInset = .zero
        couponTitle.attributedText = viewModel.title
        couponDescription.attributedText = viewModel.description
        couponCode.attributedText = viewModel.code
        copyCodeButton.setAttributedTitle(viewModel.buttonLabel, for: .normal)
        copyCodeButton.backgroundColor = .kinDeepSkyBlue
        copyCodeButton.adjustsImageWhenDisabled = false
        couponCode.clipsToBounds = false
        let shape = CAShapeLayer()
        shape.path = UIBezierPath(roundedRect: couponCode.bounds.insetBy(dx: -10.0, dy: 0.0), cornerRadius: 4.0).cgPath
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeColor = UIColor.kinLightBlueGrey.cgColor
        shape.lineWidth = 2.0
        couponCode.layer.addSublayer(shape)
        Kin.track { try SpendRedeemPageViewed(kinAmount: biData.amount, offerID: biData.offerId, orderID: biData.orderId, redeemTrigger: biData.trigger) }
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        let transition = SheetTransition()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transition
        self.dismiss(animated: true)
    }
    
    @IBAction func copyCodeButtonTapped(_ sender: Any) {
        UIPasteboard.general.string = viewModel.code.string
        transitionToConfirmed()
        Kin.track { try SpendRedeemButtonTapped(kinAmount: biData.amount, offerID: biData.offerId, orderID: biData.orderId) }
    }
    
    func transitionToConfirmed() {
        let shape = CAShapeLayer()
        shape.frame = view.convert(copyCodeButton.bounds, from: copyCodeButton).insetBy(dx: 1.0, dy: 1.0)
        shape.fillColor = UIColor.kinDeepSkyBlue.cgColor
        shape.lineWidth = 2.0
        shape.strokeColor = UIColor.kinDeepSkyBlue.cgColor
        shape.path = UIBezierPath(roundedRect: shape.bounds, cornerRadius: shape.bounds.height / 2.0).cgPath
        view.layer.addSublayer(shape)
        let vShape = CAShapeLayer()
        vShape.bounds = CGRect(x: 0.0, y: 0.0, width: 19.0, height: 15.0)
        vShape.position = shape.position
        vShape.strokeColor = UIColor.kinDeepSkyBlue.cgColor
        vShape.lineWidth = 2.0
        let vPath = UIBezierPath()
        vPath.move(to: CGPoint(x: 0.0, y: 7.0))
        vPath.addLine(to: CGPoint(x: 7.0, y: 15.0))
        vPath.addLine(to: CGPoint(x: 19.0, y: 0.0))
        vShape.path = vPath.cgPath
        vShape.fillColor = UIColor.clear.cgColor
        vShape.strokeStart = 0.0
        vShape.strokeEnd = 0.0
        view.layer.addSublayer(vShape)
        let duration = 0.64
        copyCodeButton.alpha = 0.0
        let pathAnimation = Animations.animation(with: "path", duration: duration * 0.25, beginTime: 0.0, from: shape.path!, to: UIBezierPath(roundedRect: shape.bounds.insetBy(dx: (shape.bounds.width / 2.0) - 25.0, dy: 0.0), cornerRadius: shape.bounds.height / 2.0).cgPath)
        let fillAnimation = Animations.animation(with: "fillColor", duration: duration * 0.55, beginTime: duration * 0.45, from: UIColor.kinDeepSkyBlue.cgColor, to: UIColor.kinWhite.cgColor)
        let vPathAnimation = Animations.animation(with: "strokeEnd", duration: duration * 0.45, beginTime: duration * 0.55, from: 0.0, to: 1.0)
        let shapeGroup = Animations.animationGroup(animations: [pathAnimation, fillAnimation], duration: duration)
        let vPathGroup = Animations.animationGroup(animations: [vPathAnimation], duration: duration)
        shape.add(shapeGroup, forKey: "shrink")
        vShape.add(vPathGroup, forKey: "vStroke")
        
        UIView.animate(withDuration: 0.1, animations: {  [weak self] in
            self?.closeButton.alpha = 0.0
        }) { [weak self] finished in
            self?.closeButton.isHidden = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.0) {
            let transition = SheetTransition()
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = transition
            self.dismiss(animated: true)
        }
        
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        Kin.track { try RedeemURLTapped() }
        var urlToOpen = URL
        if URL.scheme == nil {
            if let finalURL = Foundation.URL(string: "http://\(URL.absoluteString)") {
                urlToOpen = finalURL
            } else {
                return false
            }
        }
        let sfController = SFSafariViewController(url: urlToOpen)
        sfController.modalPresentationStyle = .overFullScreen
        self.present(sfController, animated: true)
        return false
    }
}
