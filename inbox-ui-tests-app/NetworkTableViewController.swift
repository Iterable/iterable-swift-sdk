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
    var requests = [
        SerializedRequest(method: "POST",
                          host: "host.example.com",
                          path: "path1",
                          queryParameters: ["q1": "v1"],
                          headers: ["h1": "v1"],
                          bodyString: "bodyString"),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return requests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let request = requests[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "networkCell", for: indexPath) as! NetworkCell
        
        cell.pathLbl.text = request.path
        
        return cell
    }
}
