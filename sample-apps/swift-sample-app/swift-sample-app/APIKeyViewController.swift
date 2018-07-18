//
//  SettingsViewController.swift
//  swift-sample-app
//
//  Created by Tapash Majumder on 7/17/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import UIKit

class APIKeyViewController: UIViewController {
    @IBOutlet weak var apiKeyTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func setApiKeyTapped(_ sender: UIButton) {
        guard let text = apiKeyTextField.text, !text.isEmpty else {
            let alert = UIAlertController(title: "API Key Required", message: "Please enter your Iterable API Key.", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) { (action) in
                self.apiKeyTextField.becomeFirstResponder()
            }
            alert.addAction(action)
            present(alert, animated: true)
            return
        }

        UserDefaults.standard.set(text, forKey: "iterableApiKey")
        
        let alert = UIAlertController(title: "Relaunch Application", message: "Your Iterable API Key has been set. You need to launch the application again. Application will now exit.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            exit(0)
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
}
