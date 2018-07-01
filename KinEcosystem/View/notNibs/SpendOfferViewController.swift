//
//  SpendOfferViewController.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 26/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit
import CoreDataStack
import KinUtil

enum SpendOfferError: Error {
    case userCanceled
}

@available(iOS 9.0, *)
class SpendOfferViewController: KinViewController {
    
    struct BIData {
        var amount: Double
        var offerId: String
    }
    var viewModel: SpendViewModel!
    var biData: BIData!
    fileprivate(set) var spend = Promise<Void>()
    @IBOutlet weak var spendImageView: UIImageView!
    @IBOutlet weak var spendTitle: UILabel!
    @IBOutlet weak var spendDescription: UILabel!
    @IBOutlet weak var spendButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.image.then(on: .main) { [weak self] result in
            self?.spendImageView.image = result.image
        }
        spendTitle.attributedText = viewModel.title
        spendDescription.numberOfLines = 2
        spendDescription.attributedText = viewModel.description
        spendButton.setAttributedTitle(viewModel.buttonLabel, for: .normal)
        spendButton.backgroundColor = .kinDeepSkyBlue
        spendButton.adjustsImageWhenDisabled = false
        Kin.track { try ConfirmPurchasePageViewed(kinAmount: biData.amount, offerID: biData.offerId, orderID: "") }
    }

    @IBAction func closeButtonTapped(_ sender: Any) {
        spend.signal(SpendOfferError.userCanceled)
        let transition = SheetTransition()
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = transition
        self.dismiss(animated: true)
    }

    @IBAction func confirmTapped(_ sender: Any) {
        Kin.track { try ConfirmPurchaseButtonTapped(kinAmount: biData.amount, offerID: biData.offerId, orderID: "" ) }
        spendButton.isEnabled = false
        spend.signal(())
        transitionToConfirmed()
    }

    func transitionToConfirmed() {
        let shape = CAShapeLayer()
        shape.frame = view.convert(spendButton.bounds, from: spendButton).insetBy(dx: 1.0, dy: 1.0)
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
        spendButton.alpha = 0.0
        let pathAnimation = Animations.animation(with: "path", duration: duration * 0.25, beginTime: 0.0, from: shape.path!, to: UIBezierPath(roundedRect: shape.bounds.insetBy(dx: (shape.bounds.width / 2.0) - 25.0, dy: 0.0), cornerRadius: shape.bounds.height / 2.0).cgPath)
        let fillAnimation = Animations.animation(with: "fillColor", duration: duration * 0.55, beginTime: duration * 0.45, from: UIColor.kinDeepSkyBlue.cgColor, to: UIColor.kinWhite.cgColor)
        let vPathAnimation = Animations.animation(with: "strokeEnd", duration: duration * 0.45, beginTime: duration * 0.55, from: 0.0, to: 1.0)
        let shapeGroup = Animations.animationGroup(animations: [pathAnimation, fillAnimation], duration: duration)
        let vPathGroup = Animations.animationGroup(animations: [vPathAnimation], duration: duration)
        shape.add(shapeGroup, forKey: "shrink")
        vShape.add(vPathGroup, forKey: "vStroke")

        let fadeDuration = duration / 2.0

        UIView.animate(withDuration: 0.1, animations: {  [weak self] in
            self?.closeButton.alpha = 0.0
        }) { [weak self] finished in
            self?.closeButton.isHidden = true
        }
        
        Kin.track { try SpendThankyouPageViewed(kinAmount: biData.amount, offerID: biData.offerId, orderID: "") }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.72) { [weak self] in

            guard   let spendTitle = self?.spendTitle,
                    let spendDescription = self?.spendDescription else  { return }
            UIView.transition(with: spendTitle, duration: fadeDuration, options: .transitionCrossDissolve, animations: {
                self?.spendTitle.attributedText = self?.viewModel.confirmation?.title
            })
            UIView.transition(with: spendDescription, duration: fadeDuration, options: .transitionCrossDissolve, animations: {
                self?.spendDescription.attributedText = self?.viewModel.confirmation?.description
            })
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 2.0) {
            let transition = SheetTransition()
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = transition
            self.dismiss(animated: true)
        }

    }

}
