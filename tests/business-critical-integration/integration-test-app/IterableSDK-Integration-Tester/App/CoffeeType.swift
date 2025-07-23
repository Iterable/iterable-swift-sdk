//
//  CoffeeType.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 6/20/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

struct CoffeeType {
    let name: String
    let image: UIImage
    
    static let cappuccino = CoffeeType(name: "Cappuccino", image: #imageLiteral(resourceName: "Cappuccino"))
    static let latte = CoffeeType(name: "Latte", image: #imageLiteral(resourceName: "Latte"))
    static let mocha = CoffeeType(name: "Mocha", image: #imageLiteral(resourceName: "Mocha"))
    static let black = CoffeeType(name: "Black", image: #imageLiteral(resourceName: "Black"))
}
