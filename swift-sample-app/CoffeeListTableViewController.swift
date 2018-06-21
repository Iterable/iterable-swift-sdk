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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else {
            return
        }
        
        guard let coffeeViewController = segue.destination as? CoffeeViewController else {
            return
        }
        
        coffeeViewController.coffee = coffees[indexPath.row]
    }

}

extension CoffeeListTableViewController : StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeListTableViewController"
}

