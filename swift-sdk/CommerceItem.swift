//
//  Created by Tapash Majumder on 6/6/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

/**
 `CommerceItem` represents a product. These are used by the commerce API; see [IterableAPI trackPurchase:items:dataFields:]
 */
@objcMembers public class CommerceItem: NSObject {
    /** id of this product */
    public var id: String
    
    /** name of this product */
    public var name: String
    
    /** price of this product */
    public var price: NSNumber
    
    /** quantity of this product */
    public var quantity: UInt
    
    /**
     Creates a `CommerceItem` with the specified properties
     
     - parameters:
     - id:          id of the product
     - name:        name of the product
     - price:       price of the product
     - quantity:    quantity of the product
     
     - returns: an instance of `CommerceItem` with the specified properties
     */
    public init(id: String, name: String, price: NSNumber, quantity: UInt) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
    }
    
    /**
     A Dictionary respresentation of this item
     
     - returns: An NSDictionary representing this item
     */
    public func toDictionary() -> [AnyHashable: Any] {
        ["id": id,
         "name": name,
         "price": price,
         "quantity": quantity]
    }
}
