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

extension NSAttributedString {
    var kin: NSAttributedString {
        guard let kinImage = UIImage.bundleImage("balanceKinIcon")?
            .padded(with: UIEdgeInsets(top: 0.0, left: 2.0, bottom: 0.0, right: 2.0))?
            .withRenderingMode(.automatic),
            let font = self.attributes(at: 0, effectiveRange: nil)[.font] as? UIFont else {
                return self
        }

        let kinAttachment = NSTextAttachment()
        kinAttachment.bounds = CGRect(x: 0, y: (font.capHeight - kinImage.size.height).rounded() / 2, width: kinImage.size.width, height: kinImage.size.height)
        kinAttachment.image = kinImage

        return NSAttributedString(attachment: kinAttachment) + self
    }

    func applyingTextAlignment(_ textAlignment: NSTextAlignment) -> NSAttributedString {
        let mAttributedString = NSMutableAttributedString(attributedString: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        mAttributedString.addAttribute(.paragraphStyle,
                                       value: paragraphStyle,
                                       range: NSRange(location: 0, length: string.count))
        return mAttributedString
    }

    func applyingTextColor(_ color: UIColor) -> NSAttributedString {
        let mAttributedString = NSMutableAttributedString(attributedString: self)
        mAttributedString.addAttribute(.foregroundColor,
                                       value: color,
                                       range: NSRange(location: 0, length: string.count))
        return mAttributedString
    }
}

func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSMutableAttributedString
{
    let result = NSMutableAttributedString()
    result.append(lhs)
    result.append(rhs)
    return result
}



