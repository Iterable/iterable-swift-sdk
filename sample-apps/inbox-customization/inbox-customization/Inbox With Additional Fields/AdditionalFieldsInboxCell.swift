//
//  Created by Tapash Majumder on 2020-01-15.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class AdditionalFieldsInboxCell: IterableInboxCell {
    @IBOutlet weak var discountLbl: UILabel!
    
    @IBAction func buyNowTapped(_: UIButton) {
        ITBInfo()
    }
}
