# UI Components provided by IterableSDK

## IterableBannerView for iOS

This repository contains a collection of IBDesignable components for iOS, specifically the IterableBannerView. The IterableBannerView is a versatile component that allows you to create visually appealing banners with customizable features. With this component, you can easily display titles, descriptions, buttons, and image within a banner, providing a seamless user experience.

#### Usage
- Open the storyboard or XIB file where you want to use the IterableBannerView.
- In the Object Library, search for "View" or browse the list of available components.
- Drag and drop the View onto your canvas.
- Click on Identity Inspector.
- Insert class name "IterableBannerView"

    ![ClassName](/BannerViewDocuments/ClassName.jpg)

### Design Samples
![Sample 1](/BannerViewDocuments/Sample1.jpg)
![Sample 2](/BannerViewDocuments/Sample2.jpg)
![Sample 3](/BannerViewDocuments/Sample3.jpg)

### Customized
Customize the various properties of the IterableBannerView in the Attributes Inspector, including:

![Property](/BannerViewDocuments/Property.jpg)

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

### Image View:
    - Choose the background color
    - Border radius
    - Border color
    - Select an image
    - Set the size (width and height)

Preview and adjust the appearance of the IterableBannerView directly in Interface Builder.
Build and run your project to see the IterableBannerView in action on your device or simulator.

## Video Preview
<!-- ![Preview](/BannerViewDocuments/full_design_video.mp4) -->

### Full Sample Code

```swift
import UIKit
import Foundation
import IterableSDK

struct IterableBannerData {
    let title: String
    let description: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String?
    let image: UIImage?
}

class DesignSampleViewController: UIViewController, IterableBannerViewDelegate {
    
    // Bind IBOutlet, using view from storyboard
    @IBOutlet weak var bannerViewBottom: IterableBannerView!
    
    var iterableBannerData: [IterableBannerData] = []
    
    // Create Programatically
    var bannerView = IterableBannerView(frame: CGRectMake(0, 50, 300, 159))
    var bannerViewSecond = IterableBannerView()
    
    //MARK:
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadBannerData()
    }    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadBannerView()
        loadSecondBanner()
    }
    
    //MARK:
    func loadBannerData() {
        let firstBanner = IterableBannerData(title: "Try Gold Plan", description: "Enjoy 14 days of Premium", primaryButtonTitle: "Pay now", secondaryButtonTitle: nil, image: UIImage.init(named: "flag"))
        let secondBanner = IterableBannerData(title: "Try Silver Plan", description: "Enjoy 7 days of Premium \n Second line description", primaryButtonTitle: "Pay for 7 days", secondaryButtonTitle: nil, image: UIImage.init(named: "selectedsubscription.png"))
        iterableBannerData = [firstBanner,secondBanner]
    }
    
    func loadBannerView() {
        bannerView.tag = 1
        bannerView.iterableBannerViewDelegate = self
        bannerView.frame = CGRectMake(16, 50, self.view.frame.width - 32, 159)
        bannerView.labelTitle.text = iterableBannerData[0].title
        bannerView.labelDescription.text = iterableBannerData[0].description
        bannerView.btnPrimary.setTitle(iterableBannerData[0].primaryButtonTitle, for: .normal)
        
        if ((iterableBannerData[0].secondaryButtonTitle) != nil) {
            bannerView.btnSecondary.setTitle(iterableBannerData[0].secondaryButtonTitle, for: .normal)
            bannerView.isShowSecondaryButton = true
        }
        else {
            bannerView.isShowSecondaryButton = false
        }
        
        bannerView.imgView.image = iterableBannerData[0].image
        bannerViewSecond.imgViewBorderWidth = 10
        bannerViewSecond.imgViewBorderColor = UIColor.systemOrange
        // Add a button action, an alternate option for a button event without using the delegate method.
        // bannerView.btnPrimary.addTarget(self, action: #selector (btnPrimaryPressed), for: .touchUpInside)
        self.view.addSubview(bannerView);
    }
    
    func loadSecondBanner() {
        bannerViewSecond.tag = 2
        bannerViewSecond.iterableBannerViewDelegate = self
        bannerViewSecond.contentView.backgroundColor = UIColor.systemYellow
        bannerViewSecond.iterableBannerViewDelegate = self
        
        bannerViewSecond.labelTitle.text = iterableBannerData[1].title
        bannerViewSecond.labelDescription.text = iterableBannerData[1].description + "new \n new"
        bannerViewSecond.btnPrimary.setTitle(iterableBannerData[1].primaryButtonTitle, for: .normal)
        
        if ((iterableBannerData[1].secondaryButtonTitle) != nil) {
            bannerViewSecond.btnSecondary.setTitle(iterableBannerData[1].secondaryButtonTitle, for: .normal)
            bannerViewSecond.isShowSecondaryButton = true
        }
        else {
            bannerViewSecond.isShowSecondaryButton = false
        }
        bannerViewSecond.center = self.view.center
        bannerViewSecond.frame = CGRectMake(16, 159 + 50 + 25, self.view.frame.width - 32, 200)
        bannerViewSecond.imgView.image = iterableBannerData[1].image
        bannerViewSecond.imgView.backgroundColor =  UIColor.clear
        bannerViewSecond.imgViewBorderWidth = 0
        bannerViewSecond.imgViewBorderColor = UIColor.clear
        self.view.addSubview(bannerViewSecond);
    }
    
    //MARK: Button Pressed add target method
    @objc func btnPrimaryPressed () {
        print("btnPrimaryPressed")
    }
    
    //MARK:IterableBannerViewDelegate Methods
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
Happy designing with IterableBannerView!
