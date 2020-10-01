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
    @IBOutlet weak var loginOutBarButton: UIBarButtonItem!
    
    // Set this value to show search.
    var searchTerm: String? {
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
        
        if LoginViewController.checkIterableEmailOrUserId().eitherPresent {
            loginOutBarButton.title = "Logout"
        } else {
            loginOutBarButton.title = "Login"
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
    
    // MARK: - TableViewDataSourceDelegate Functions
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        filtering ? filteredCoffees.count : coffees.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "coffeeCell", for: indexPath)
        
        let coffeeList = filtering ? filteredCoffees : coffees
        let coffee = coffeeList[indexPath.row]
        cell.textLabel?.text = coffee.name
        cell.imageView?.image = coffee.image
        
        return cell
    }
    
    // MARK: Tap Handlers
    
    @IBAction func loginOutBarButtonTapped(_: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LoginNavController")
        present(vc, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
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
        .black,
    ]
    
    private var filtering = false
    private var filteredCoffees: [CoffeeType] = []
    private var searchController: UISearchController!
}

extension CoffeeListTableViewController: UISearchControllerDelegate {
    func willDismissSearchController(_: UISearchController) {
        searchTerm = nil
    }
}

extension CoffeeListTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text, !text.isEmpty {
            filtering = true
            filteredCoffees = coffees.filter { (coffeeType) -> Bool in
                coffeeType.name.lowercased().contains(text.lowercased())
            }
        } else {
            filtering = false
        }
        tableView.reloadData()
    }
}

extension CoffeeListTableViewController: StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeListTableViewController"
}
