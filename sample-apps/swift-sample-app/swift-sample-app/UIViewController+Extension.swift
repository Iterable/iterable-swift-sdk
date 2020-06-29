//
//  UIViewController+Extension.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 5/17/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import Foundation
import UIKit

/// If you want a UIViewController declared in a storyboard to be code instantiatable. You declare
/// your UIViewController to adhere to StoryboardInstantiatable protocol.
/// This ensures that you have `create()` and `createNav()` methods to easily instantiate your ViewController.
public protocol StoryboardInstantiable {
    static var storyboardName: String { get } // Name of Storyboard
    static var storyboardId: String { get } // Name of this view controller in Storyboard
}

public extension StoryboardInstantiable where Self: UIViewController {
    /// Will create a strongly typed instance of this VC.
    static func createFromStoryboard() -> Self {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: storyboardId) as! Self
    }
    
    /// Will create a UINavigationController with this VC as the rootViewController.
    static func createNavFromStoryboard() -> UINavigationController {
        UINavigationController(rootViewController: createFromStoryboard())
    }
}
