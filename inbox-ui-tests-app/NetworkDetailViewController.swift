//
//  Created by Tapash Majumder on 9/2/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

@testable import IterableSDK

class NetworkDetailViewController: UITableViewController {
    @IBOutlet weak var bodyLbl: UILabel!
    
    var request: SerializableRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        if let body = request.body {
            bodyLbl.text = String(data: try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted), encoding: .utf8)!
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in _: UITableView) -> Int {
        1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        1
    }
}
