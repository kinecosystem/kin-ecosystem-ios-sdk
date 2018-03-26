//
//  BlockchainData.swift
//  KinEcosystem
//
//  Created by Elazar Yifrach on 20/02/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import Foundation
import CoreData

class BlockchainData: NSManagedObject, Decodable {
    
    @NSManaged public var transaction_id: String?
    @NSManaged public var sender_address: String?
    @NSManaged public var recipient_address: String?
    @NSManaged public var order: Order?
    @NSManaged public var offer: Offer?
    
    enum BlockchainDataKeys: String, CodingKey {
        case transaction_id
        case sender_address
        case recipient_address
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let managedObjectContext = decoder.userInfo[.context] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "BlockchainData", in: managedObjectContext) else {
                fatalError()
        }
        
        self.init(entity: entity, insertInto: managedObjectContext)
        let values = try decoder.container(keyedBy: BlockchainDataKeys.self)
        
        transaction_id = try values.decodeIfPresent(String.self, forKey: .transaction_id)
        sender_address = try values.decodeIfPresent(String.self, forKey: .sender_address)
        recipient_address = try values.decodeIfPresent(String.self, forKey: .recipient_address)
        
    }
}
