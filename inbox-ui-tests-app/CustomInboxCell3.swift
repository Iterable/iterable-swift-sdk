//
//  Created by Tapash Majumder on 2020-01-08.
//  Copyright © 2020 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class CustomInboxCell3: IterableInboxCell {
    @IBOutlet weak var discountLbl: UILabel!
    
    @IBAction func buyNowTapped(_: UIButton) {
        ITBInfo()
    }
}
