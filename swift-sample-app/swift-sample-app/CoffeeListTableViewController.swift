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
    // Whether we are checking for inAppMessages
    let checkForInApp = false
    let inAppCheckInterval = 5.0

    /**
     Set this value to show search.
     */
    var searchTerm: String? = nil {
        didSet {
            if let searchTerm = searchTerm, !searchTerm.isEmpty {
                DispatchQueue.main.async {
                    self.searchController.searchBar.text = searchTerm
                    self.searchController.searchBar.becomeFirstResponder()
                    self.searchController.becomeFirstResponder()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = "Search"
        searchController.delegate = self
        searchController.searchResultsUpdater = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if checkForInApp {
            timer = Timer.scheduledTimer(withTimeInterval: inAppCheckInterval, repeats: true) {_ in
                IterableAPI.instance?.spawn(inAppNotification: { (_) in
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if checkForInApp {
            timer?.invalidate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let searchTerm = searchTerm, !searchTerm.isEmpty {
            DispatchQueue.main.async {
                self.searchController.searchBar.text = searchTerm
                self.searchController.searchBar.becomeFirstResponder()
                self.searchController.becomeFirstResponder()
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtering ? filteredCoffees.count : coffees.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coffeeCell", for: indexPath)
        
        let coffeeList = filtering ? filteredCoffees : coffees
        let coffee = coffeeList[indexPath.row]
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

    // MARK: Private
    private let coffees: [CoffeeType] = [
        .cappuccino,
        .latte,
        .mocha,
        .black
    ]
    
    private var filtering = false
    private var filteredCoffees: [CoffeeType] = []
    private var searchController: UISearchController!
    private var timer: Timer?
}

extension CoffeeListTableViewController : UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        searchTerm = nil
    }
}

extension CoffeeListTableViewController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            filtering = true
            filteredCoffees = coffees.filter({ (coffeeType) -> Bool in
                coffeeType.name.lowercased().contains(text.lowercased())
            })
        } else {
            filtering = false
        }
        tableView.reloadData()
    }
}

extension CoffeeListTableViewController : StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeListTableViewController"
}

