//
//  CouponCode.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 13/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class CouponCode : OrderResult, Decodable {
    
    @NSManaged public var coupon_code: String
    
    enum CouponCodeKeys: String, CodingKey {
        case coupon_code
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "CouponCode", in: managedObjectContext) else {
                fatalError()
        }
        
        // initializing subclasses of OrderResult is more coutious than other classes.
        // Mind and keep the order of checks here
        let values = try decoder.container(keyedBy: CouponCodeKeys.self)
        if let code = try? values.decode(String.self, forKey: .coupon_code) {
            self.init(entity: entity, insertInto: managedObjectContext)
            coupon_code = code
            type = OrderResultType.coupon.rawValue
        } else {
            throw EcosystemDataError.decodeError
        }
        
        
        
    }
    
}
