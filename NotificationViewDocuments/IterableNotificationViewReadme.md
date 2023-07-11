# UI Components provided by IterableSDK

## IterableNotificationView for iOS

This repository contains a collection of IBDesignable components for iOS, specifically the IterableNotificationView. The IterableNotificationView is a versatile component that allows you to create visually appealing notifications with customizable features. With this component, you can easily display titles, descriptions, and buttons within a notification, providing a seamless user experience.

#### Usage
- Open the storyboard or XIB file where you want to use the IterableNotificationView.
- In the Object Library, search for "View" or browse the list of available components.
- Drag and drop the View onto your canvas.
- Click on Identity Inspector.
- Insert class name "IterableNotificationView"

    ![ClassName](/NotificationViewDocuments/ClassName.png)

### Design Samples
![Sample 1](/NotificationViewDocuments/Sample1.png)
![Sample 2](/NotificationViewDocuments/Sample2.png)

### Customized
Customize the various properties of the IterableNotificationView in the Attributes Inspector, including:

![Property](/NotificationViewDocuments/Property.png)

### View:
    - Set the corner radius
    - Shadow color
    - Shadow offset
    - Shadow radius
    - Background color of the view

### Title:
    - Specify the title text
    - Font size
    - Text color

### Description:
    - Set the description text.
    - Font size
    - Text color

### Primary Button:
    - Define the button text
    - Text color
    - Background color
    - Border radius

### Secondary Button:
    - Configure the button text
    - Text color
    - Background color
    - Border radius
    - Toggle its visibility.

Preview and adjust the appearance of the IterableNotificationView directly in Interface Builder.
Build and run your project to see the IterableNotificationView in action on your device or simulator.

### Full Sample Code

```swift
import UIKit
import Foundation
import IterableSDK

class DesignSampleViewController: UIViewController, NotificationViewDelegate, IterableNotificationViewDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        renderNotifications()
    }

    func renderNotifications() {
        self.loadNotification1View()
        self.loadNotification2View()
    }

    func loadNotification1View() {
        let lightRed = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        let notiView1 = IterableNotificationView()
        
        notiView1.tag = 1
        notiView1.notificationViewDelegate = self
        notiView1.frame = CGRectMake(16, 50, self.view.frame.width - 32, 159)
        notiView1.contentView.backgroundColor = lightRed
        notiView1.titleLabel.text = "Sample notification 1"
        notiView1.bodyLabel.text = "sample body text"
        
        notiView1.primaryButton.setTitle("Okay", for: .normal)
        notiView1.primaryButton.setTitleColor(.white, for: .normal)
        notiView1.primaryButton.backgroundColor = UIColor.white
        
        notiView1.secondaryButton.setTitle("cancel", for: .normal)
        notiView1.secondaryButton.setTitleColor(.white, for: .normal)
        
        self.view.addSubview(notiView1);
    }

    func loadNotification2View() {
        let lightSkyBlue = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        let notiView2 = IterableNotificationView()
        
        notiView2.tag = 1
        notiView2.notificationViewDelegate = self
        notiView2.frame = CGRectMake(16, 220, self.view.frame.width - 32, 159)
        notiView2.contentView.backgroundColor = lightSkyBlue
        notiView2.titleLabel.text = "Sample notification 2"
        notiView2.bodyLabel.text = "sample body text"
        
        notiView2.primaryButton.setTitle("Okay", for: .normal)
        notiView2.primaryButton.backgroundColor = UIColor.white
        notiView2.primaryButton.setTitleColor(.white, for: .normal)
        
        notiView2.secondaryButton.setTitle("cancel", for: .normal)
        notiView2.secondaryButton.setTitleColor(.white, for: .normal)
        
        self.view.addSubview(notiView2);
    }

    //MARK: Button Pressed add target method
    @objc func btnPrimaryPressed () {
        print("btnPrimaryPressed")
    }

    //MARK: IterableBannerViewDelegate Methods
    func didPressPrimaryButton(button: UIButton, viewTag: Int) {
        print("didPressPrimaryButton", viewTag)
    }

    func didPressSecondaryButton(button: UIButton, viewTag: Int) {
        print("didPressSecondaryButton", viewTag)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
```
Happy designing with IterableNotificationView!