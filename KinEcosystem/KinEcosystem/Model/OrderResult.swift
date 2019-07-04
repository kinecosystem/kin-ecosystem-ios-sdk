//
//  OrderResult.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

enum OrderResultType: String {
    case coupon
    case jwt
}

class OrderResult: NSManagedObject {
    
    @NSManaged public var order: Order?
    @NSManaged public var type: String?
    
}


