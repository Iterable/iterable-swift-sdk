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
        
        // Create a long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
               
        // Optionally, set the minimum press duration (default is 0.5 seconds)
        longPressRecognizer.minimumPressDuration = 1
               
        // Add the gesture recognizer to the view you want to detect the long press on
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    // The handler function for the long press gesture
      @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
          if sender.state == .began {
              // Handle the long press action
              print("Long press detected")
              
              // You can add any additional logic here
              let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let vc = storyboard.instantiateViewController(withIdentifier: "BugBashViewController")
              present(vc, animated: true)
          }
      }
    
    @IBAction func loginInOutButtonTapped(_: UIButton) {
        switch LoginViewController.checkIterableEmailOrUserId() {
        case .email: // logout
            IterableAPIHelper.currentRetry = 0;
            IterableAPI.email = nil
        case .userId: // logout
            IterableAPIHelper.currentRetry = 0;
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
