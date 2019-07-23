//
//  BadgeBarButtonItem.swift
//  Base64
//
//  Created by Corey Werner on 01/11/2018.
//

import UIKit

class BadgeBarButtonItem: UIBarButtonItem {
    private var defaultImage: UIImage?
    private var badgeImage: UIImage?
    
    var hasBadge: Bool = false {
        didSet {
            image = hasBadge ? badgeImage : defaultImage
        }
    }
    
    convenience init(image: UIImage?, badgeImage: UIImage?, target: Any?, action: Selector?) {
        self.init(image: image, style: .plain, target: target, action: action)

        defaultImage = image

        guard let image = image, let badgeImage = badgeImage else {
            return
        }

        self.badgeImage = image.overlayed(with: badgeImage)
    }
    
    public override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
