//
//  IterableBannerView.swift
//  Fiterable
//
//  Created by Vivek on 25/05/23.
//

import Foundation
import UIKit

public protocol IterableBannerViewDelegate: NSObject {
    func didPressPrimaryButton(button: UIButton, viewTag:Int)
    func didPressSecondaryButton(button: UIButton, viewTag:Int)
}

@IBDesignable
public class IterableBannerView:UIView {
    
    // Delegate Methods
    weak public var iterableBannerViewDelegate: IterableBannerViewDelegate!
    
    /// Set background color of view in container view.
    @IBOutlet weak public var contentView: UIView!
    
    /// IterableBannerView Title Label
    @IBOutlet weak public var labelTitle: UILabel!
    
    /// IterableBannerView Description Label
    @IBOutlet weak public var labelDescription: UILabel!
    
    /// IterableBannerView Primary button.
    @IBOutlet weak public var btnPrimary: UIButton!
    
    /// IterableBannerView Secondary button.
    @IBOutlet weak public var btnSecondary: UIButton!
    
    /// IterableBannerView Image View.
    @IBOutlet weak public var imgView: UIImageView!
    
    @IBOutlet weak public var imageViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet weak public var imageViewHeightConstraint:NSLayoutConstraint!

    // MARK: IterableBannerView init method
    /// IterableBannerView init method
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        // Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    func xibSetup() {
        self.contentView = self.loadViewFromNib()
        self.contentView.frame = self.bounds
        self.setDefaultValue()
        self.addSubview(self.contentView)
    }
    
    func loadViewFromNib() -> UIView? {
        print("inside")
        let bundle = Bundle(for: Self.self)
        let nib = UINib(nibName: "IterableBannerView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        view?.backgroundColor = UIColor.clear
        view?.layer.masksToBounds = false
        return view
    }
    
    //MARK: Helper public function to update view in storyboard
    //    public override func prepareForInterfaceBuilder() {
    //        super.prepareForInterfaceBuilder()
    //    }
    
    //MARK: Assign Default Value
    ///setDefaultValue assign default values to IterableBannerView
    public func setDefaultValue() {
        self.backgroundColor = UIColor.clear
        
        bannerCornerRadius = 10
        bannerShadowColor = UIColor.lightGray
        bannerShadowWidth = 1
        bannerShadowHeight = 1
        bannerShadowRadius = 3
        bannerBackgroundColor = UIColor.purple
        
        // Title Label
        //        titleFontName = "HelveticaNeue-Bold"
        titleFontSize = 21
        titleTextColor = UIColor.white
        
        // Description Label
        //        descriptionFontName = "HelveticaNeue"
        descriptionFontSize = 17
        descriptionTextColor = UIColor.white
        
        // Buttons Primary
        btnPrimaryText = "Primary"
        btnPrimaryColor = UIColor.white
        btnPrimaryTextColor = UIColor.purple
        btnPrimaryBorderRadius = 17
        
        // Button Secondary
        btnSecondaryText = "Secondary"
        btnSecondaryColor = UIColor.clear
        btnSecondaryTextColor = UIColor.white
        btnSecondaryBorderRadius = 0
        isShowSecondaryButton = true
        
        // Image View
        imgView.backgroundColor = UIColor.white
        imgViewCornerRadius = 10
        imgViewBorderWidth  = 1
        imgViewBorderColor = UIColor.gray
        //        self.layoutIfNeeded()
    }
    
    //MARK: Helper public function to set dynamic view
    //    public func setupViewDynamic() {
    //        setDefaultValue()
    //    }
    
    //MARK: IterableBannerView Corner Radius
    /// IterableBannerView corner radius
    @IBInspectable public var bannerCornerRadius: Double = 10 {
        didSet {
            contentView.layer.cornerRadius = bannerCornerRadius
            contentView.clipsToBounds = true
            layer.masksToBounds = false
        }
    }
    
    // MARK: IterableBannerView Shadow Color
    /// IterableBannerView shadow color
    @IBInspectable public var bannerShadowColor: UIColor = UIColor.lightGray {
        didSet {
            contentView.layer.shadowColor = bannerShadowColor.cgColor
            contentView.layer.shadowRadius = 3
            layer.masksToBounds = false
            contentView.layer.shadowOffset = CGSize(width: 5, height: 5)
            contentView.layer.masksToBounds = false
            contentView.layer.shadowOpacity = 1
        }
    }
    
    //MARK: IterableBannerView Shadow Offset Width
    /// IterableBannerView shadow width CGSize
    @IBInspectable public var bannerShadowWidth: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: bannerShadowWidth, height: bannerShadowHeight)
        }
    }
    
    //MARK: IterableBannerView Shadow Offset Height
    /// IterableBannerView shadow height CGSize
    @IBInspectable public var bannerShadowHeight: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: bannerShadowWidth, height: bannerShadowHeight)
        }
    }
    
    //MARK: IterableBannerView Shadow Radius
    /// IterableBannerView shadow radius
    @IBInspectable public var bannerShadowRadius: Double = 3 {
        didSet {
            layer.shadowRadius = bannerShadowRadius
        }
    }
    
    //MARK: IterableBannerView Background Color
    /// IterableBannerView background color
    @IBInspectable public var bannerBackgroundColor: UIColor? = UIColor.purple {
        didSet {
            self.backgroundColor = UIColor.clear
            self.contentView.backgroundColor = bannerBackgroundColor!
        }
    }
    
    //    //MARK:Title Lable Property
    //    @IBInspectable @objc var font: UIFont? {
    //        didSet {
    //            labelTitle.font = font
    //        }
    //    }
    
    // MARK: IterableBannerView Title
    @IBInspectable public var title: String = "Banner Title" {
        didSet {
            labelTitle.text = title
            self.layoutIfNeeded()
        }
    }
    
    /// IterableBannerView title font size
    @IBInspectable public var titleFontSize: CGFloat = 21 {
        didSet {
            labelTitle.font = UIFont.init(name: "HelveticaNeue-Bold", size: titleFontSize)
        }
    }
    
    
    // MARK: IterableBannerView Title Text Color
    /// IterableBannerView title text color
    @IBInspectable public var titleTextColor: UIColor = UIColor.purple {
        didSet {
            labelTitle.textColor = titleTextColor
        }
    }
    
    //    @IBInspectable public var descriptionFontName: String = "HelveticaNeue" {
    //        didSet {
    //            labelDescription.font = UIFont.init(name: descriptionFontName, size: descriptionFontSize)
    //        }
    //    }
    
    // MARK: IterableBannerView Title
    @IBInspectable public var descriptionText: String = "Description Text" {
        didSet {
            labelDescription.text = descriptionText
            self.layoutIfNeeded()
        }
    }
    
    // MARK: IterableBannerView Description Font Size
    /// IterableBannerView description font size.
    @IBInspectable public var descriptionFontSize: CGFloat = 17 {
        didSet {
            labelDescription.font = UIFont.init(name: "HelveticaNeue", size: descriptionFontSize)
        }
    }
    
    // MARK: IterableBannerView Description Text Color
    /// IterableBannerView description text color
    @IBInspectable public var descriptionTextColor: UIColor = UIColor.purple {
        didSet {
            labelDescription.textColor = descriptionTextColor
        }
    }
    
    //MARK: Primary Button Property
    // MARK: Primary Button Text Color
    /// Primary button text color
    @IBInspectable public var btnPrimaryText: String = "Primary" {
        didSet {
            btnPrimary.setTitle(btnPrimaryText, for: .normal)
        }
    }
    
    // MARK: Primary Button Background Color
    /// Primary button background color
    @IBInspectable public var btnPrimaryColor: UIColor = UIColor.purple {
        didSet {
            btnPrimary.backgroundColor = btnPrimaryColor
        }
    }
    
    // MARK: Primary Button Text Color
    /// Primary button text color
    @IBInspectable public var btnPrimaryTextColor: UIColor = UIColor.white {
        didSet {
            btnPrimary.setTitleColor(btnPrimaryTextColor, for: .normal)
        }
    }
    
    // MARK: Primary Button Border Radius
    /// Primary button border radius
    @IBInspectable public var btnPrimaryBorderRadius: Double = 17 {
        didSet {
            btnPrimary.layer.cornerRadius = btnPrimaryBorderRadius
        }
    }
    
    // MARK: Primary Button Pressed
    /// Primary button on touchup inside event
    @IBAction public func primaryButtonPressed(_ sender: UIButton) {
        if (iterableBannerViewDelegate != nil) {
            iterableBannerViewDelegate.didPressSecondaryButton(button: sender, viewTag: self.tag)
        }
        else {
            // Delegate not found
        }
    }
    
    // MARK: Secondary Button Property
    /// Secondary button text
    @IBInspectable public var btnSecondaryText: String = "Secondary" {
        didSet {
            btnSecondary.setTitle(btnSecondaryText, for: .normal)
        }
    }
    
    //MARK: Secondary Button Background Color
    /// Secondary button background color
    @IBInspectable public var btnSecondaryColor: UIColor = UIColor.clear {
        didSet {
            btnSecondary.backgroundColor = btnSecondaryColor
        }
    }
    
    //MARK: Secondary Button Text Color
    /// Secondary button text color
    @IBInspectable public var btnSecondaryTextColor: UIColor = UIColor.white {
        didSet {
            btnSecondary.setTitleColor(btnSecondaryTextColor, for: .normal)
        }
    }
    
    //MARK: Secondary Button Border Radius
    /// Secondary button border radius
    @IBInspectable public var btnSecondaryBorderRadius: Double = 0 {
        didSet {
            btnSecondary.layer.cornerRadius = btnSecondaryBorderRadius
        }
    }
    
    //MARK: Secondary Button Show or Hide
    /// Secondary button show or hide.
    @IBInspectable public var isShowSecondaryButton: Bool = false {
        didSet {
            btnSecondary.isHidden = !isShowSecondaryButton
        }
    }
    
    //MARK: Secondary Button Press Method
    /// Secondary button on press event
    @IBAction func secondaryButtonPressed(_ sender: UIButton) {
        if (iterableBannerViewDelegate != nil) {
            iterableBannerViewDelegate.didPressSecondaryButton(button: sender, viewTag: self.tag)
        }
        else  {
            // Delegate not found
        }
        
    }
    
    //MARK: Image Property
    /// Image View background color
    @IBInspectable public var imgViewBackgroundColor: UIColor = UIColor.white {
        didSet {
            imgView.backgroundColor = imgViewBackgroundColor
        }
    }
    
    //MARK: Image View Corner Radius
    /// Image View corner radius
    @IBInspectable public var imgViewCornerRadius: Double = 10 {
        didSet {
            imgView.layer.cornerRadius = imgViewCornerRadius
        }
    }
    
    //MARK: Image View Border Width
    /// Image View border width
    @IBInspectable public var imgViewBorderWidth: Double = 1 {
        didSet {
            imgView.layer.borderWidth = imgViewBorderWidth
        }
    }
    
    //MARK: Image View Border Color
    /// Image View border color
    @IBInspectable public var imgViewBorderColor: UIColor = UIColor.gray {
        didSet {
            imgView.layer.borderColor = imgViewBorderColor.cgColor
        }
    }
    
    //MARK: Image View Image
    /// Image View image
    @IBInspectable public var imgViewImage: UIImage? {
        didSet {
            imgView.image = imgViewImage
            imgView.contentMode = .scaleAspectFit
        }
    }
    
    //MARK: Image View Width
//    /// Image View width constraint
    @IBInspectable public var imgViewWidth:Double = 60 {
        didSet {
            imageViewWidthConstraint.constant = imgViewWidth
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    //MARK: Image View Height
    /// Image View width constraint
    @IBInspectable public var imgViewHeight: Double = 60 {
        didSet {
            imageViewHeightConstraint.constant = imgViewHeight
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
}

