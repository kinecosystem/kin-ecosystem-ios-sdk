//
//  OrderResult.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class OrderResult: NSManagedObject, Decodable {
    
    @NSManaged public var coupon_code: String?
    @NSManaged public var failure_message: String?
    @NSManaged public var order: Order?
    
    enum OrderResultKeys: String, CodingKey {
        case coupon_code
        case failure_message
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "OrderResult", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        let values = try decoder.container(keyedBy: OrderResultKeys.self)
        
        coupon_code = try values.decodeIfPresent(String.self, forKey: .coupon_code)
        failure_message = try values.decodeIfPresent(String.self, forKey: .coupon_code)
    }
    
}


