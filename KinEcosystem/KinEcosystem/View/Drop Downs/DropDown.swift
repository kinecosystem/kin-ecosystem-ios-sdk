//
//  DropDown.swift
//  KinEcosystem
//
//  Created by Alon Genosar on 25/07/2019.
//  Copyright © 2019 Kik Interactive. All rights reserved.
//

import UIKit

typealias DropDownCallback = (String?)->Void

protocol DropDownable {
    func resume()
    func resign()
}

class DropDown: NSObject {
    static private var currentView:UIView?
    static private var currentId:String?
    static private var timer:Timer?
    static let padding:CGFloat = 10
    static let margin:CGFloat = 10
    class func show(view:UIView, timout:TimeInterval = 3.0, _ callback:DropDownCallback? = nil) {
        DropDown.hide(animation:false) { id in
            let container = UIView(frame: CGRect(x: margin,
                                                 y: margin,
                                                 width:  UIApplication.shared.keyWindow!.width + padding * 2,
                                                 height: view.height + padding + 2))
            container.layoutMargins = UIEdgeInsets(top: 10,left: 10,bottom: 10,right: 10)
            container.layer.cornerRadius = 10

            //TODO add drop container
            //container uiview, round edged, margins
            currentView = view
            currentId = NSUUID().uuidString
            UIApplication.shared.keyWindow?.addSubview(currentView!)
            currentView?.centerX =  currentView!.superview!.centerX
            currentView!.y = currentView!.height
            UIView.animate(withDuration: 0.5, animations: {
                currentView?.y = 10 + UIApplication.shared.keyWindow!.layoutMargins.top
                currentView?.alpha = 1
            }) { finished in
                if let dropdownable = currentView as? DropDownable {
                    dropdownable.resume()
                }
                callback?(currentId)
            }
        }
    }

    class func hide(animation:Bool = true, id:String? = nil, _ callback:DropDownCallback? = nil) {
        timer?.invalidate()
        guard id == currentId else { callback?(nil); return }
        if let dropdownable = currentView as? DropDownable { dropdownable.resign() }

        UIView.animate(withDuration: 0.5, animations: {
            currentView?.alpha = 0
        }) { finished in

            currentView?.removeFromSuperview()
            currentView = nil
            currentId = nil
            callback?(nil)
        }
    }
}

//Mark: DropDown Factory
extension DropDown {
    static var balance:UIView {
        return UIView()
    }
    static var welcome:UIView {
        return UIView()
    }
}
