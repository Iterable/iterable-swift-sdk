//
//  CoffeeListTableViewController.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 6/15/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

/*
import UIKit

import IterableSDK

class CoffeeListTableViewController: UITableViewController {
    @IBOutlet weak var loginOutBarButton: UIBarButtonItem!
    @IBOutlet weak var embeddedMessagesBarButton: UIBarButtonItem!
    
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
        
        // Setup integration test mode if enabled
        setupIntegrationTestMode()
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
    
    @IBAction func embeddedMessagesBarButtonTapped(_: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedMessagesViewController")
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
    
    // MARK: - Integration Test Setup
    
    private func setupIntegrationTestMode() {
        // Add test UI elements for integration testing
        addSDKInitializationButton()
        addTestUserButton()
        addSDKStatusIndicator()
    }
    
    private func addSDKInitializationButton() {
        let initButton = UIButton(type: .system)
        initButton.setTitle("Initialize SDK", for: .normal)
        initButton.backgroundColor = .systemBlue
        initButton.setTitleColor(.white, for: .normal)
        initButton.layer.cornerRadius = 8
        initButton.accessibilityIdentifier = "initialize-sdk-button"
        initButton.addTarget(self, action: #selector(initializeSDKTapped), for: .touchUpInside)
        
        view.addSubview(initButton)
        initButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            initButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: -210),
            initButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            initButton.widthAnchor.constraint(equalToConstant: 180),
            initButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func addTestUserButton() {
        let userButton = UIButton(type: .system)
        userButton.setTitle("Add Test User", for: .normal)
        userButton.backgroundColor = .systemGreen
        userButton.setTitleColor(.white, for: .normal)
        userButton.layer.cornerRadius = 8
        userButton.accessibilityIdentifier = "add-test-user-button"
        userButton.addTarget(self, action: #selector(addTestUserTapped), for: .touchUpInside)
        
        view.addSubview(userButton)
        userButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: 210),
            userButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            userButton.widthAnchor.constraint(equalToConstant: 180),
            userButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func addSDKStatusIndicator() {
        let statusLabel = UILabel()
        statusLabel.text = "SDK Not Initialized"
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = .systemRed
        statusLabel.accessibilityIdentifier = "sdk-status-indicator"
        
        view.addSubview(statusLabel)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            statusLabel.widthAnchor.constraint(equalToConstant: 300),
            statusLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func initializeSDKTapped() {
        print("🧪 SDK Initialize button tapped")
        
        // Call AppDelegate method to initialize SDK
        AppDelegate.initializeSDKForTesting()
        
        // Update status to show SDK is ready
        updateStatusLabel(text: "SDK Initialized", color: .systemBlue, identifier: "sdk-ready-indicator")
        
        // Hide the initialize button
        if let initButton = view.subviews.first(where: { $0.accessibilityIdentifier == "initialize-sdk-button" }) {
            initButton.isHidden = true
        }
    }
    
    @objc private func addTestUserTapped() {
        print("🧪 Add Test User button tapped")
        
        // Call AppDelegate method to add test user
        AppDelegate.addTestUserForTesting()
        
        // Update status to show user is added
        updateStatusLabel(text: "Test User Added - Ready for Testing", color: .systemGreen, identifier: "sdk-ready-indicator")
        
        // Hide the add user button
        if let userButton = view.subviews.first(where: { $0.accessibilityIdentifier == "add-test-user-button" }) {
            userButton.isHidden = true
        }
    }
    
    private func updateStatusLabel(text: String, color: UIColor, identifier: String) {
        if let statusLabel = view.subviews.first(where: { $0.accessibilityIdentifier == "sdk-status-indicator" || $0.accessibilityIdentifier == "sdk-ready-indicator" }) as? UILabel {
            statusLabel.text = text
            statusLabel.textColor = color
            statusLabel.accessibilityIdentifier = identifier
        }
    }
}

extension CoffeeListTableViewController: StoryboardInstantiable {
    static var storyboardName = "Main"
    static var storyboardId = "CoffeeListTableViewController"
}

*/
