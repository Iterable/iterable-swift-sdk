//
//  LoginViewController.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 7/17/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

import IterableSDK

class LoginViewController: UIViewController {
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var logInOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        switch LoginViewController.checkIterableEmailOrUserId() {
        case let .email(email):
            emailAddressTextField.text = email
            emailAddressTextField.isEnabled = false
            logInOutButton.setTitle("Logout", for: .normal)
        case let .userId(userId):
            userIdTextField.text = userId
            userIdTextField.isEnabled = false
            logInOutButton.setTitle("Logout", for: .normal)
        case .none:
            emailAddressTextField.text = nil
            emailAddressTextField.isEnabled = true
            userIdTextField.text = nil
            userIdTextField.isEnabled = true
            logInOutButton.setTitle("Login", for: .normal)
        }
    }
    
    @IBAction func loginInOutButtonTapped(_: UIButton) {
        switch LoginViewController.checkIterableEmailOrUserId() {
        case .email: // logout
            IterableAPI.email = nil
        case .userId: // logout
            IterableAPI.userId = nil
        case .none: // login
            if let text = emailAddressTextField.text, !text.isEmpty {
                IterableAPI.email = text
            } else if let text = userIdTextField.text, !text.isEmpty {
                IterableAPI.userId = text
            }
        }
        
        presentingViewController?.dismiss(animated: true)
    }
    
    enum IterableEmailOrUserIdCheckResult {
        case email(String)
        case userId(String)
        case none
        
        var eitherPresent: Bool {
            switch self {
            case .email, .userId:
                return true
            case .none:
                return false
            }
        }
    }
    
    class func checkIterableEmailOrUserId() -> IterableEmailOrUserIdCheckResult {
        if let email = IterableAPI.email {
            return .email(email)
        } else if let userId = IterableAPI.userId {
            return .userId(userId)
        } else {
            return .none
        }
    }
    
    @IBAction func doneButtonTapped(_: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
}
