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
    @IBOutlet weak var emailAddressTextField: UITextField!
    @IBOutlet weak var logInOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let email = IterableAPI.email {
            emailAddressTextField.text = email
            emailAddressTextField.isEnabled = false
            logInOutButton.setTitle("Logout", for: .normal)
        } else {
            emailAddressTextField.text = nil
            emailAddressTextField.isEnabled = true
            logInOutButton.setTitle("Login", for: .normal)
        }
    }

    @IBAction func loginInOutButtonTapped(_ sender: UIButton) {
        if let _ = IterableAPI.email {
            // logout
            IterableAPI.email = nil
        } else {
            // login
            if let text = emailAddressTextField.text, !text.isEmpty {
                IterableAPI.email = text
            }
        }
        presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
}
