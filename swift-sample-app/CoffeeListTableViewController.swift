//
//  CoffeeListTableViewController.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 6/15/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class CoffeeListTableViewController: UITableViewController {
    struct CoffeeType {
        let name: String
        let image: UIImage
        
        static let cappuccino = CoffeeType(name: "Cappuccino",image: #imageLiteral(resourceName: "Cappuccino"))
        static let latte = CoffeeType(name: "Latte", image: #imageLiteral(resourceName: "Latte"))
        static let mocha = CoffeeType(name: "Mocha", image: #imageLiteral(resourceName: "Mocha"))
        static let black = CoffeeType(name: "Black", image: #imageLiteral(resourceName: "Black"))
    }
    
    private let coffees: [CoffeeType] = [
        .cappuccino,
        .latte,
        .mocha,
        .black
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return coffees.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coffeeCell", for: indexPath)
        
        let coffee = coffees[indexPath.row]
        cell.textLabel?.text = coffee.name
        cell.imageView?.image = coffee.image
        
        return cell
    }
}
