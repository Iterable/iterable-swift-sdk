//
//  IterableInboxNavigationViewController.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 4/30/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

open class IterableInboxNavigationViewController: UINavigationController {
    /// Do not use this
    private override init(rootViewController: UIViewController) {
        ITBInfo()
        super.init(rootViewController: rootViewController)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        ITBInfo()
        super.init(coder: aDecoder)
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        ITBInfo()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
