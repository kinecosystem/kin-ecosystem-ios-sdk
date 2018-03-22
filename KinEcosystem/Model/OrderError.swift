//
//  OrderError.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 13/03/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class OrderError: NSManagedObject, Decodable {
    
    @NSManaged public var code: Int32
    @NSManaged public var error: String
    @NSManaged public var message: String?
    @NSManaged public var order: Order?
    
    enum OrderErrorKeys: String, CodingKey {
        case code
        case error
        case message
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "OrderError", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        let values = try decoder.container(keyedBy: OrderErrorKeys.self)
        code = try values.decode(Int32.self, forKey: .code)
        error = try values.decode(String.self, forKey: .error)
        message = try values.decodeIfPresent(String.self, forKey: .message)
    }
    
}
