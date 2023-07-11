# UI Components provided by IterableSDK

## IterableCardView for iOS

This repository contains a collection of IBDesignable components for iOS, specifically the IterableCardView. The IterableCardView is a versatile component that allows you to create visually appealing notifications with customizable features. With this component, you can easily display Images, titles, descriptions, and buttons within a cards, providing a seamless user experience.

#### Usage
- Open the storyboard or XIB file where you want to use the IterableCardView.
- In the Object Library, search for "View" or browse the list of available components.
- Drag and drop the View onto your canvas.
- Click on Identity Inspector.
- Insert class name "IterableCardView"

    ![ClassName](/CardViewDocuments/ClassName.png)

### Design Samples
![Sample 1](/CardViewDocuments/Sample1.png)
![Sample 2](/CardViewDocuments/Sample2.png)

### Customized
Customize the various properties of the IterableCardView in the Attributes Inspector, including:

![Property](/CardViewDocuments/Property.png)

### View:
    - Set the corner radius
    - Shadow color
    - Shadow offset
    - Shadow radius
    - Background color of the view

### Image View:
    - Choose the background color
    - Border radius
    - Border color
    - Select an image
    - Set the size (width and height)

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

Preview and adjust the appearance of the IterableCardView directly in Interface Builder.
Build and run your project to see the IterableCardView in action on your device or simulator.

### Full Sample Code

```swift
import UIKit
import Foundation
import IterableSDK

class DesignSampleViewController: UIViewController, IterableCardViewDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        renderNotifications()
    }

    func renderNotifications() {
        self.loadCard1View()
        self.loadCard2View()
    }

    func loadCard1View() {
        let lightRed = UIColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
        let cardView1 = IterableCardView()

        cardView1.tag = 1
        cardView1.iterableCardViewDelegate = self
        cardView1.frame = CGRectMake(16, 10, self.view.frame.width - 32, 159)
        cardView1.imgView.image = UIImage(named: "card_1_home")
        cardView1.labelTitle.text = "Card title 1"
        cardView1.labelDescription.text = "sample body text"
        cardView1.labelTitle.textColor = UIColor.black
        cardView1.labelDescription.textColor = UIColor.black

        cardView1.btnPrimary.setTitle("okay", for: .normal)
        cardView1.btnPrimary.setTitleColor(.white, for: .normal)
        cardView1.btnPrimary.backgroundColor = UIColor.black

        cardView1.btnSecondary.setTitle("cancel", for: .normal)
        cardView1.btnSecondary.setTitleColor(.black, for: .normal)

        self.view.addSubview(cardView1);
    }

    func loadCard2View() {
        let lightSkyBlue = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        let cardView2 = IterableCardView()

        cardView2.tag = 2
        cardView2.iterableCardViewDelegate = self
        cardView2.frame = CGRectMake(16, 380, self.view.frame.width - 32, 159)
        cardView2.imgView.image = UIImage(named: "card_2_home")
        cardView2.labelTitle.text = "Card title 2"
        cardView2.labelTitle.textColor = UIColor.black
        cardView2.labelDescription.text = "sample body text"
        cardView2.labelDescription.textColor = UIColor.black

        cardView2.btnPrimary.setTitle("okay", for: .normal)
        cardView2.btnPrimary.setTitleColor(.white, for: .normal)
        cardView2.btnPrimary.backgroundColor = UIColor.black

        cardView2.btnSecondary.setTitle("cancel", for: .normal)
        cardView2.btnSecondary.setTitleColor(.black, for: .normal)

        self.view.addSubview(cardView2);
    }

    //MARK: Button Pressed add target method
    @objc func btnPrimaryPressed () {
        print("btnPrimaryPressed")
    }

    //MARK: IterableCardViewDelegate Methods
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
Happy designing with IterableCardView!