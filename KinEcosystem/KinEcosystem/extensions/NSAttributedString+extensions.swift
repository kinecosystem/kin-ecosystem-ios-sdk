//
//  NSAttributedString+extensions.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 05/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension String {
    
    func attributed(_ size: CGFloat, weight: UIFont.Weight, color: UIColor) -> NSAttributedString {
        return NSAttributedString(string: self,
                                  attributes: [.font : UIFont.systemFont(ofSize: size, weight: weight),
                                                             .foregroundColor : color])
    }
    
}

func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString
{
    let result = NSMutableAttributedString()
    result.append(lhs)
    result.append(rhs)
    return result
}
