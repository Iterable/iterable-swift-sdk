//
//  Created by Tapash Majumder on 9/2/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@testable import IterableSDK

class NetworkCell: UITableViewCell {
    @IBOutlet weak var pathLbl: UILabel!
    @IBOutlet weak var headersLbl: UILabel!
    @IBOutlet weak var queryParametersLbl: UILabel!
    @IBOutlet weak var bodyLbl: UILabel!
}

class NetworkTableViewController: UITableViewController {
    var requests = [SerializableRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in _: UITableView) -> Int {
        1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        requests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = requests[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "networkCell", for: indexPath)
        
        cell.textLabel?.text = request.path
        cell.detailTextLabel?.text = request.serializedString
        cell.detailTextLabel?.accessibilityIdentifier = "serializedString"
        return cell
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRow = indexPath.row
        guard selectedRow < requests.count else {
            return
        }
        let request = requests[selectedRow]
        
        let detailVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: String(describing: NetworkDetailViewController.self)) as! NetworkDetailViewController
        
        detailVC.request = request
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @IBAction func clearBtnTapped(_: UIBarButtonItem) {
        ITBInfo()
        
        requests = []
        tableView.reloadData()
    }
}
