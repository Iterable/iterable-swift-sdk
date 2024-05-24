//
//  BugBashViewController.swift
//  swift-sample-app
//
//  Created by vishwa on 22/05/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
import UIKit
import IterableSDK

class BugBashViewController: UIViewController {
    
    @IBOutlet weak var maxRetryCountLabel: UILabel!
    @IBOutlet weak var currentRetryCountLabel: UILabel!
    @IBOutlet weak var lastRetryTimeLabel: UILabel!
    @IBOutlet weak var lastErrorCodeLabel: UILabel!
    
    @IBOutlet weak var invalidButton: UIButton!
    @IBOutlet weak var validButton: UIButton!
    @IBOutlet weak var nullButton: UIButton!
    @IBOutlet weak var expiredButton: UIButton!
    @IBOutlet weak var mySwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    
    
    var authRetryPaused = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.lastRetryTimeLabel.text = IterableAPIHelper.lastRetryTime
            self.currentRetryCountLabel.text = String(IterableAPI.getAuthManager()?.getRetryCount() ?? 0)
        }
        
        mySwitch.isOn = IterableAPI.getAuthManager()?.getPauseAuthRetry() ?? false
        maxRetryCountLabel.text = String(IterableAPIHelper.maxRetry)

        if IterableAPIHelper.authType == .VALID {
            validButtonClicked()
        } else if IterableAPIHelper.authType == .INVALID {
            invalidButtonClicked()
        }else if IterableAPIHelper.authType == .NULL {
            nullButtonClicked()
        } else if IterableAPIHelper.authType == .EXPIRED {
            expiredButtonClicked()
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        authRetryPaused = !authRetryPaused
        IterableAPIHelper.currentRetry = 0
        IterableAPI.pauseAuthRetries(authRetryPaused)
        if sender.isOn {
           print("Switch is ON")
           // Add logic for when switch is turned ON
        } else {
           print("Switch is OFF")
           // Add logic for when switch is turned OFF
        }
    }
    
    @IBAction func validButtonClicked() {
        IterableAPIHelper.authType = IterableAPIHelper.AuthType.VALID
        filledImage(button: validButton)
        unfilledImage(button: invalidButton)
        unfilledImage(button: nullButton)
        unfilledImage(button: expiredButton)
    }
    
    @IBAction func invalidButtonClicked() {
        IterableAPIHelper.authType = IterableAPIHelper.AuthType.INVALID
        filledImage(button: invalidButton)
        unfilledImage(button: validButton)
        unfilledImage(button: nullButton)
        unfilledImage(button: expiredButton)
    }
    
    @IBAction func nullButtonClicked() {
        IterableAPIHelper.authType = IterableAPIHelper.AuthType.NULL
        filledImage(button: nullButton)
        unfilledImage(button: invalidButton)
        unfilledImage(button: validButton)
        unfilledImage(button: expiredButton)
    }
    
    @IBAction func expiredButtonClicked() {
        IterableAPIHelper.authType = IterableAPIHelper.AuthType.EXPIRED
        filledImage(button: expiredButton)
        unfilledImage(button: invalidButton)
        unfilledImage(button: nullButton)
        unfilledImage(button: validButton)
    }
    
    func filledImage(button : UIButton){
        if #available(iOS 13.0, *) {
            let filledImage = UIImage(systemName: "circle.circle.fill")
            button.setImage(filledImage, for: .normal)
       } else {
           // Fallback for iOS 12 and below
           let filledImage = UIImage(named: "circle.circle.fill")
           button.setImage(filledImage, for: .normal)
       }
    }
    
    func unfilledImage(button: UIButton){
        if #available(iOS 13.0, *) {
            let circleImage = UIImage(systemName: "circle")
            button.setImage(circleImage, for: .normal)
       } else {
           // Fallback for iOS 12 and below
           let circleImage = UIImage(named: "circle")
           button.setImage(circleImage, for: .normal)
       }
    }
    
    @IBAction func saveButtonClicked() {
        
    }
}
