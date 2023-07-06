//
//  File.swift
//  
//
//  Created by Vishal on 06/07/23.
//

import Foundation
import UIKit

public protocol IterableNotificationViewDelegate: NSObject {
    func didPressPrimaryButton(button: UIButton, viewTag:Int)
    func didPressSecondaryButton(button: UIButton, viewTag:Int)
}

@IBDesignable
class IterableNotificationView: UIView {
    
    // Delegate Methods
    weak public var notificationViewDelegate: IterableNotificationViewDelegate!
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var bodyLabel: UITextField!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var secondaryButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.contentView = self.loadViewFromNib()
        self.contentView.frame = self.bounds
        self.setDefaultValue()
        self.addSubview(self.contentView)
    }
    
    private func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: "IterableNotificationView", bundle: .module)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        view?.backgroundColor = UIColor.clear
        view?.layer.masksToBounds = false
        return view
    }
    
    ///setDefaultValue assign default values to NotificationView
    public func setDefaultValue() {
        self.backgroundColor = UIColor.clear
        
        //Content View
        notificationCornerRadius = 10
        notificationShadowColor = UIColor.lightGray
        notificationShadowWidth = 1
        notificationShadowHeight = 1
        notificationShadowRadius = 3
        notificationBackgroundColor = UIColor.gray
        
        // Title Label
        titleFontSize = 21
        titleTextColor = UIColor.black
        
        // Description Label
        descriptionFontSize = 17
        descriptionTextColor = UIColor.black
        
        // Buttons Primary
        btnPrimaryText = "Primary"
        btnPrimaryColor = UIColor.white
        btnPrimaryTextColor = UIColor.purple
        btnPrimaryBorderRadius = 17
        
        // Button Secondary
        btnSecondaryText = "Secondary"
        btnSecondaryColor = UIColor.clear
        btnSecondaryTextColor = UIColor.purple
        btnSecondaryBorderRadius = 0
        isShowSecondaryButton = true
    }
    
    //MARK: NotificationView Corner Radius
    /// NotificationView corner radius
    @IBInspectable public var notificationCornerRadius: Double = 10 {
        didSet {
            contentView.layer.cornerRadius = notificationCornerRadius
            contentView.clipsToBounds = true
            layer.masksToBounds = false
        }
    }
    
    // MARK: NotificationView Shadow Color
    /// NotificationView shadow color
    @IBInspectable public var notificationShadowColor: UIColor = UIColor.lightGray {
        didSet {
            contentView.layer.shadowColor = notificationShadowColor.cgColor
            contentView.layer.shadowRadius = 3
            layer.masksToBounds = false
            contentView.layer.shadowOffset = CGSize(width: 5, height: 5)
            contentView.layer.masksToBounds = false
            contentView.layer.shadowOpacity = 1
        }
    }
    
    //MARK: NotificationView Shadow Offset Width
    /// NotificationView shadow width CGSize
    @IBInspectable public var notificationShadowWidth: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: notificationShadowWidth, height: notificationShadowHeight)
        }
    }
    
    //MARK: NotificationView Shadow Offset Height
    /// NotificationView shadow height CGSize
    @IBInspectable public var notificationShadowHeight: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: notificationShadowWidth, height: notificationShadowHeight)
        }
    }
    
    //MARK: NotificationView Shadow Radius
    /// NotificationView shadow radius
    @IBInspectable public var notificationShadowRadius: Double = 3 {
        didSet {
            layer.shadowRadius = notificationShadowRadius
        }
    }
    
    //MARK: NotificationView Background Color
    /// NotificationView background color
    @IBInspectable public var notificationBackgroundColor: UIColor? = UIColor.gray {
        didSet {
            self.backgroundColor = UIColor.clear
            self.contentView.backgroundColor = notificationBackgroundColor!
        }
    }
    
    // MARK: NotificationView Title
    @IBInspectable public var title: String = "Title" {
        didSet {
            titleLabel.text = title
            self.layoutIfNeeded()
        }
    }
    
    /// NotificationView title font size
    @IBInspectable public var titleFontSize: CGFloat = 21 {
        didSet {
            titleLabel.font = UIFont.init(name: "HelveticaNeue-Bold", size: titleFontSize)
        }
    }
    
    
    // MARK: NotificationView Title Text Color
    /// NotificationView title text color
    @IBInspectable public var titleTextColor: UIColor = UIColor.black {
        didSet {
            titleLabel.textColor = titleTextColor
        }
    }
    
    // MARK: NotificationView Title
    @IBInspectable public var descriptionText: String = "Body Text" {
        didSet {
            bodyLabel.text = descriptionText
            self.layoutIfNeeded()
        }
    }
    
    // MARK: NotificationView Description Font Size
    /// NotificationView description font size.
    @IBInspectable public var descriptionFontSize: CGFloat = 17 {
        didSet {
            bodyLabel.font = UIFont.init(name: "HelveticaNeue", size: descriptionFontSize)
        }
    }
    
    // MARK: NotificationView Description Text Color
    /// NotificationView description text color
    @IBInspectable public var descriptionTextColor: UIColor = UIColor.black {
        didSet {
            bodyLabel.textColor = descriptionTextColor
        }
    }
    
    // MARK: Primary Button Text Color
    /// Primary button text color
    @IBInspectable public var btnPrimaryText: String = "Primary" {
        didSet {
            primaryButton.setTitle(btnPrimaryText, for: .normal)
        }
    }
    
    // MARK: Primary Button Background Color
    /// Primary button background color
    @IBInspectable public var btnPrimaryColor: UIColor = UIColor.purple {
        didSet {
            primaryButton.backgroundColor = btnPrimaryColor
        }
    }
    
    // MARK: Primary Button Text Color
    /// Primary button text color
    @IBInspectable public var btnPrimaryTextColor: UIColor = UIColor.white {
        didSet {
            primaryButton.setTitleColor(btnPrimaryTextColor, for: .normal)
        }
    }
    
    // MARK: Primary Button Border Radius
    /// Primary button border radius
    @IBInspectable public var btnPrimaryBorderRadius: Double = 17 {
        didSet {
            primaryButton.layer.cornerRadius = btnPrimaryBorderRadius
        }
    }
    
    // MARK: Primary Button Pressed
    /// Primary button on touchup inside event
    @IBAction public func primaryButtonPressed(_ sender: UIButton) {
        if (notificationViewDelegate != nil) {
            notificationViewDelegate.didPressSecondaryButton(button: sender, viewTag: self.tag)
        }
        else {
            // Delegate not found
        }
    }
    
    // MARK: Secondary Button Property
    /// Secondary button text
    @IBInspectable public var btnSecondaryText: String = "Secondary" {
        didSet {
            secondaryButton.setTitle(btnSecondaryText, for: .normal)
        }
    }
    
    //MARK: Secondary Button Background Color
    /// Secondary button background color
    @IBInspectable public var btnSecondaryColor: UIColor = UIColor.clear {
        didSet {
            secondaryButton.backgroundColor = btnSecondaryColor
        }
    }
    
    //MARK: Secondary Button Text Color
    /// Secondary button text color
    @IBInspectable public var btnSecondaryTextColor: UIColor = UIColor.purple {
        didSet {
            secondaryButton.setTitleColor(btnSecondaryTextColor, for: .normal)
        }
    }
    
    //MARK: Secondary Button Border Radius
    /// Secondary button border radius
    @IBInspectable public var btnSecondaryBorderRadius: Double = 0 {
        didSet {
            secondaryButton.layer.cornerRadius = btnSecondaryBorderRadius
        }
    }
    
    //MARK: Secondary Button Show or Hide
    /// Secondary button show or hide.
    @IBInspectable public var isShowSecondaryButton: Bool = false {
        didSet {
            secondaryButton.isHidden = !isShowSecondaryButton
        }
    }
    
    //MARK: Secondary Button Press Method
    /// Secondary button on press event
    @IBAction func secondaryButtonPressed(_ sender: UIButton) {
        if (notificationViewDelegate != nil) {
            notificationViewDelegate.didPressSecondaryButton(button: sender, viewTag: self.tag)
        }
        else  {
            // Delegate not found
        }
        
    }
}
