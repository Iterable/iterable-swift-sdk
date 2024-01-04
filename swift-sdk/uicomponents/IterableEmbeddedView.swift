//
//  IterableEmbeddedView.swift
//  Fiterable
//
//  Created by Vivek on 25/05/23.
//

import Foundation
import UIKit


//TODO: Featuring in D6
//public protocol IterableEmbeddedViewDelegate: NSObject {
//    func didPressPrimaryButton(button: UIButton, viewTag: Int, message: IterableEmbeddedMessage?)
//    func didPressSecondaryButton(button: UIButton, viewTag: Int, message: IterableEmbeddedMessage?)
//    func didPressBanner(banner: IterableEmbeddedView, viewTag: Int, message: IterableEmbeddedMessage?)
//}

@IBDesignable
public class IterableEmbeddedView:UIView {
    
    // Delegate Methods
//    weak public var iterableEmbeddedViewDelegate: IterableEmbeddedViewDelegate!
    
    /// Set background color of view in container view.
    @IBOutlet weak public var contentView: UIView!
    @IBOutlet weak var innerContentView: UIView!
    
    /// IterableEmbeddedView Title Label
    @IBOutlet weak public var labelTitle: UILabel!
    
    /// IterableEmbeddedView Description Label
    @IBOutlet weak public var labelDescription: UILabel!
    
    /// IterableEmbeddedView Primary button.
    @IBOutlet weak public var primaryBtn: IterableEMButton!
    
    /// IterableEmbeddedView Secondary button.
    @IBOutlet weak public var secondaryBtn: IterableEMButton!
    
    /// IterableEmbeddedView Buttons stack view
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var horizontalButtonStackViewSpacer: UIView!
    
    /// IterableEmbeddedView Image View.
    @IBOutlet weak public var imgView: UIImageView!
    @IBOutlet weak public var cardImageView: UIImageView!
    @IBOutlet weak var cardImageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleToTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak public var imageViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet weak public var imageViewHeightConstraint:NSLayoutConstraint!
    

    // MARK: Embedded Message Content
    /// Title
    var EMtitle: String? = "Placeholding Title" {
        didSet {
            if let title = EMtitle {
                labelTitle.text = title
                labelTitle.isHidden = false
            } else {
                labelTitle.isHidden = true
            }
        }
    }
    
    /// Description
    var EMdescription: String? = "Placeholding Description" {
        didSet {
            if let description = EMdescription {
                labelDescription.text = description
                labelDescription.isHidden = false
            } else {
                labelDescription.isHidden = true
            }
        }
    }
    
    /// Image
    public var EMimage: UIImage? = nil {
        didSet {
            if let image = EMimage {
                imgView.image = image
                cardImageView.image = image
            } else {
                imgView.isHidden = true
                cardImageView.isHidden = true
            }
        }
    }

    /// Primary Button Text
    public var EMbuttonText: String? = "Placeholding BTN 1" {
        didSet {
            if let btn = EMbuttonText {
                primaryBtn.titleText = btn
                primaryBtn.isHidden = false
            } else {
                primaryBtn.isHidden = true
            }
        }
    }
    
    /// Secondary Button Text
    public var EMbuttonTwoText: String? = "Placeholding BTN 2" {
        didSet {
            if let btn = EMbuttonTwoText {
                secondaryBtn.titleText = btn
                secondaryBtn.isHidden = false
            } else {
                secondaryBtn.isHidden = true
            }
        }
    }
    
    /// Associated Embedded Message
    public var message: IterableEmbeddedMessage? = nil
    
    /// Layout style of Embedded Message
    public var EMstyle: IterableEmbeddedViewType = IterableEmbeddedViewType.banner {
        didSet {
            switch EMstyle {
            case .card:
                imgView.isHidden = true
                let shouldShowCardImageView = EMimage != nil
                bannerBorderColor = UIColor(red: 0.88, green: 0.87, blue: 0.87, alpha: 1.00)
                if shouldShowCardImageView {
                    // Show cardImageView
                    cardImageView.isHidden = false
                    cardImageTopConstraint.isActive = true
                    titleToTopConstraint.isActive = false
                } else {
                    // Hide cardImageView and deactivate its constraints
                    cardImageView.isHidden = true
                    cardImageTopConstraint.isActive = false
                    titleToTopConstraint.isActive = true

                    // Remove cardImageView from its superview and release it
                    cardImageView.removeFromSuperview()
                    cardImageView = nil
                }
            case .banner:
                imgView.isHidden = EMimage == nil
                bannerBorderColor = UIColor(red: 0.88, green: 0.87, blue: 0.87, alpha: 1.00)
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
            case .notification:
                imgView.isHidden = true
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
                bannerBackgroundColor = UIColor(red: 0.90, green: 0.98, blue: 1.00, alpha: 1.00)
                bannerBorderColor = UIColor(red: 0.76, green: 0.94, blue: 0.99, alpha: 1.00)
                titleTextColor = UIColor(red: 0.14, green: 0.54, blue: 0.66, alpha: 1.00)
                descriptionTextColor = UIColor(red: 0.14, green: 0.54, blue: 0.66, alpha: 1.00)
                primaryBtnColor = UIColor.white
                primaryBtnTextColor = UIColor(red: 0.14, green: 0.54, blue: 0.66, alpha: 1.00)
                secondaryBtnColor = UIColor(red: 0.90, green: 0.98, blue: 1.00, alpha: 1.00)
                secondaryBtnTextColor = UIColor(red: 0.14, green: 0.54, blue: 0.66, alpha: 1.00)
            }
        }
    }
    

    
    // MARK: IterableEmbeddedView init method
     /// IterableEmbeddedView init method
     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
         xibSetup()
     }

    func xibSetup() {
        self.contentView = self.loadViewFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.innerContentView.clipsToBounds = true
        self.setDefaultValue()
        self.addSubview(self.contentView)
            
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: "IterableEmbeddedView", bundle: Bundle.module)
        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        view?.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        return view
    }
    
    // MARK: Assign Default Value
    ///setDefaultValue assign default values to IterableEmbeddedView
    func setDefaultValue() {
        bannerBackgroundColor = UIColor.white
        bannerBorderWidth = 1.0
        bannerBorderColor = UIColor(red: 0.88, green: 0.87, blue: 0.87, alpha: 1.00)
        bannerCornerRadius = 8.0
        bannerShadowColor = UIColor.lightGray
        bannerShadowWidth = 1
        bannerShadowHeight = 1
        bannerShadowRadius = 3
        titleFontSize = 20
        titleFontName = "HelveticaNeue-Bold"
        titleTextColor = UIColor.black
        descriptionFontSize = 18
        descriptionFontName = "HelveticaNeue"
        descriptionTextColor = UIColor.darkGray
        primaryBtnColor = UIColor.purple
        primaryButtonRoundedSides = false
        primaryBtnBorderRadius = 0
        primaryBtnTextFontSize = 16
        primaryBtnTextFontName = "HelveticaNeue"
        primaryBtnTextColor = UIColor.white
        primaryBtnTextAlignment = "center"
        secondaryBtnColor = UIColor.clear
        secondaryButtonRoundedSides = true
        secondaryBtnBorderRadius = 0
        secondaryBtnTextFontSize = 16
        secondaryBtnTextFontName = "HelveticaNeue"
        secondaryBtnTextColor = UIColor.black
        secondaryBtnTextAlignment = "left"
        imgViewBackgroundColor = UIColor.white
        imgViewCornerRadius = 10
        imgViewBorderWidth = 0
        imgViewBorderColor = UIColor.gray
        imgViewWidth = 100
        imgViewHeight = 100
    }
    
    public func configure(viewType: IterableEmbeddedViewType, config: IterableEmbeddedViewConfig?) {
        
        let cardBorderColor = UIColor(red: 0.88, green: 0.87, blue: 0.87, alpha: 1.00)
        let cardTitleTextColor = UIColor(red: 0.24, green: 0.23, blue: 0.23, alpha: 1.00)
        let cardBodyTextColor = UIColor(red: 0.47, green: 0.44, blue: 0.45, alpha: 1.00)
        let notificationBackgroundColor = UIColor(red: 0.90, green: 0.98, blue: 1.00, alpha: 1.00)
        let notificationBorderColor = UIColor(red: 0.76, green: 0.94, blue: 0.99, alpha: 1.00)
        let notificationTextColor = UIColor(red: 0.14, green: 0.54, blue: 0.66, alpha: 1.00)
        
        let cardOrBanner = viewType == IterableEmbeddedViewType.card || viewType == IterableEmbeddedViewType.banner
        
        let defaultBackgroundColor = (cardOrBanner) ? UIColor.white : notificationBackgroundColor
        let defaultBorderColor = (cardOrBanner) ? cardBorderColor : notificationBorderColor
        let defaultPrimaryBtnColor = (cardOrBanner) ? UIColor.purple : UIColor.white
        let defaultPrimaryBtnTextColor = (cardOrBanner) ? UIColor.white : notificationTextColor
        let defaultSecondaryBtnColor = (cardOrBanner) ? UIColor.white : notificationBackgroundColor
        let defaultSecondaryBtnTextColor = (cardOrBanner) ? UIColor.purple : notificationTextColor
        let defaultTitleTextColor = (cardOrBanner) ? cardTitleTextColor : notificationTextColor
        let defaultBodyTextColor = (cardOrBanner) ? cardBodyTextColor : notificationTextColor

        switch viewType {
            case .card:
                imgView.isHidden = true
                let shouldShowCardImageView = EMimage != nil
                if shouldShowCardImageView {
                    // Show cardImageView
                    cardImageView.isHidden = false
                    cardImageTopConstraint.isActive = true
                    titleToTopConstraint.isActive = false
                } else {
                    // Hide cardImageView and deactivate its constraints
                    cardImageView.isHidden = true
                    cardImageTopConstraint.isActive = false
                    titleToTopConstraint.isActive = true

                    // Remove cardImageView from its superview and release it
                    cardImageView.removeFromSuperview()
                    cardImageView = nil
                }
            case .banner:
                imgView.isHidden = EMimage == nil
                bannerBorderColor = cardBorderColor
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
            case .notification:
                imgView.isHidden = true
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
        }
        
        bannerBackgroundColor = config?.backgroundColor ?? defaultBackgroundColor
        bannerBorderColor = config?.borderColor ?? defaultBorderColor
        bannerBorderWidth = config?.borderWidth ?? 1.0
        bannerCornerRadius = config?.borderCornerRadius ?? 8.0
        primaryBtnColor = config?.primaryBtnBackgroundColor ?? defaultPrimaryBtnColor
        primaryBtnTextColor = config?.primaryBtnTextColor ?? defaultPrimaryBtnTextColor
        secondaryBtnColor = config?.secondaryBtnBackgroundColor ?? defaultSecondaryBtnColor
        secondaryBtnTextColor = config?.secondaryBtnTextColor ?? defaultSecondaryBtnTextColor
        titleTextColor = config?.titleTextColor ?? defaultTitleTextColor
        descriptionTextColor = config?.bodyTextColor ?? defaultBodyTextColor
    }

    
    @IBAction func bannerPressed(_ sender: UITapGestureRecognizer) {
        guard let EMmessage = message else {
            ITBInfo("message not set in IterableEmbeddedView. Set the property so that clickhandlers have reference")
            return
        }
        
        if let defaultAction = message?.elements?.defaultAction {
            if let clickedUrl = defaultAction.data?.isEmpty == false ? defaultAction.data : defaultAction.type {
                IterableAPI.track(embeddedMessageClick: message!, buttonIdentifier: nil, clickedUrl: clickedUrl)
                IterableAPI.embeddedManager.handleEmbeddedClick(message: EMmessage, buttonIdentifier: nil, clickedUrl: clickedUrl)
            }
        }
        
        //TODO: Delegate method
//        if (iterableEmbeddedViewDelegate != nil) {
//            iterableEmbeddedViewDelegate.didPressBanner(banner: self, viewTag: self.tag, message: message)
//        }
//        else { }
    }
    
    public var viewConfig: IterableEmbeddedViewConfig?
    
    // MARK: Banner
    /// Banner Background Color
    @IBInspectable public var bannerBackgroundColor: UIColor? = UIColor.white {
        didSet {
            self.backgroundColor = UIColor.clear
            self.innerContentView.backgroundColor = bannerBackgroundColor!
        }
    }

    /// Banner Border Width
    @IBInspectable public var bannerBorderWidth: CGFloat = 1.0 {
        didSet {
            self.layer.borderWidth = bannerBorderWidth
        }
    }
    
    /// Banner Border Color
    @IBInspectable public var bannerBorderColor: UIColor = UIColor.clear {
        didSet {
            self.layer.borderColor = bannerBorderColor.cgColor
        }
    }
    
    /// Banner Corner Radius
    @IBInspectable public var bannerCornerRadius: CGFloat = 8.0 {
        didSet {
            self.layer.cornerRadius = bannerCornerRadius
            contentView.layer.cornerRadius = bannerCornerRadius
            innerContentView.layer.cornerRadius = bannerCornerRadius
        }
    }
    
    /// Banner Shadow Color
    @IBInspectable public var bannerShadowColor: UIColor = UIColor.lightGray {
        didSet {
            contentView.layer.shadowColor = bannerShadowColor.cgColor
            contentView.layer.shadowRadius = 3
            contentView.layer.shadowOffset = CGSize(width: 5, height: 5)
            contentView.layer.shadowOpacity = 1
        }
    }
    
    /// Banner Shadow Width
    @IBInspectable public var bannerShadowWidth: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: bannerShadowWidth, height: bannerShadowHeight)
        }
    }
    
    /// Banner Shadow Height
    @IBInspectable public var bannerShadowHeight: Double = 1 {
        didSet {
            layer.shadowOffset = CGSize(width: bannerShadowWidth, height: bannerShadowHeight)
        }
    }
    
    /// Banner Shadow Radius
    @IBInspectable public var bannerShadowRadius: Double = 3 {
        didSet {
            layer.shadowRadius = bannerShadowRadius
        }
    }
    
    // MARK: Title
    /// Title Font Size
    @IBInspectable public var titleFontSize: CGFloat = 20 {
        didSet {
            labelTitle.font = UIFont.init(name: "HelveticaNeue-Bold", size: titleFontSize)
        }
    }
    
    /// Title Font Name
    @IBInspectable public var titleFontName: String = "HelveticaNeue-Bold" {
        didSet {
            labelTitle.font = UIFont.init(name: titleFontName, size: titleFontSize)
        }
    }
    
    /// Title Text Color
    @IBInspectable public var titleTextColor: UIColor = UIColor.black {
        didSet {
            labelTitle.textColor = titleTextColor
        }
    }
    
    // MARK: Description
    /// Description Font Size
    @IBInspectable public var descriptionFontSize: CGFloat = 18 {
        didSet {
            labelDescription.font = UIFont.init(name: "HelveticaNeue", size: descriptionFontSize)
        }
    }
    
    /// Description Font Name
    @IBInspectable public var descriptionFontName: String = "HelveticaNeue" {
        didSet {
            labelDescription.font = UIFont.init(name: descriptionFontName, size: descriptionFontSize)
        }
    }
    
    /// Description Text Color
    @IBInspectable public var descriptionTextColor: UIColor = UIColor.darkGray {
        didSet {
            labelDescription.textColor = descriptionTextColor
        }
    }
    
    // MARK: Primary Button
    /// Primary button background color.
    @IBInspectable public var primaryBtnColor: UIColor = UIColor.purple {
        didSet {
            primaryBtn.backgroundColor = primaryBtnColor
        }
    }
    
    /// Primary button border radius.
    @IBInspectable public var primaryButtonRoundedSides: Bool = false {
        didSet {
            primaryBtn?.isRoundedSides = primaryButtonRoundedSides
        }
    }
    
    /// Primary button border radius.
    @IBInspectable public var primaryBtnBorderRadius: Double = 0 {
        didSet {
            primaryBtn.layer.cornerRadius = primaryBtnBorderRadius
        }
    }
    
    /// Primary button font size.
    @IBInspectable public var primaryBtnTextFontSize: CGFloat = 16 {
        didSet {
            primaryBtn.fontSize = primaryBtnTextFontSize
        }
    }
    
    /// Primary button font name.
    @IBInspectable public var primaryBtnTextFontName: String = "HelveticaNeue" {
        didSet {
            primaryBtn.fontName = primaryBtnTextFontName
        }
    }
    
    /// Primary button text color.
    @IBInspectable public var primaryBtnTextColor: UIColor = UIColor.white {
        didSet {
            primaryBtn.titleColor = primaryBtnTextColor
        }
    }
    
    /// Primary button text alignment.
    @IBInspectable public var primaryBtnTextAlignment: String = "center" {
        didSet {
            primaryBtn.titleAlignment = primaryBtnTextAlignment
        }
    }
    
    /// Primary button on touchup inside event.
    @IBAction public func primaryButtonPressed(_ sender: UIButton) {
        var buttonIdentifier: String?
        let primaryButton = message?.elements?.buttons?.first
        if let primaryButtonAction = primaryButton?.action {
            buttonIdentifier = primaryButton?.id
            
            if let clickedUrl = primaryButtonAction.data?.isEmpty == false ? primaryButtonAction.data : primaryButtonAction.type {
                IterableAPI.track(embeddedMessageClick: message!, buttonIdentifier: buttonIdentifier, clickedUrl: clickedUrl)
                IterableAPI.embeddedManager.handleEmbeddedClick(message: message!, buttonIdentifier: buttonIdentifier, clickedUrl: clickedUrl)
            }
        }

        //TODO: Delegate handling
//        if (iterableEmbeddedViewDelegate != nil) {
//            iterableEmbeddedViewDelegate.didPressPrimaryButton(button: sender, viewTag: self.tag, message: message)
//        }
        else { }
    }
    
    // MARK: Second Button
    /// Secondary button background color.
    @IBInspectable public var secondaryBtnColor: UIColor = UIColor.clear {
        didSet {
            secondaryBtn.backgroundColor = secondaryBtnColor
        }
    }
    
    /// Secondary button border radius.
    @IBInspectable public var secondaryButtonRoundedSides: Bool = false {
        didSet {
            secondaryBtn?.isRoundedSides = secondaryButtonRoundedSides
        }
    }
    
    /// Secondary button border radius.
    @IBInspectable public var secondaryBtnBorderRadius: Double = 0 {
        didSet {
            secondaryBtn.layer.cornerRadius = secondaryBtnBorderRadius
        }
    }
    
    
    /// Secondary button font size.
    @IBInspectable public var secondaryBtnTextFontSize: CGFloat = 16 {
        didSet {
            secondaryBtn.fontSize = secondaryBtnTextFontSize
        }
    }
    
    /// Secondary button font name.
    @IBInspectable public var secondaryBtnTextFontName: String = "HelveticaNeue" {
        didSet {
            secondaryBtn.fontName = secondaryBtnTextFontName
        }
    }
    
    /// Secondary button text color.
    @IBInspectable public var secondaryBtnTextColor: UIColor = UIColor.black {
        didSet {
            secondaryBtn.titleColor = secondaryBtnTextColor
        }
    }
    
    /// Secondary button text alignment.
    @IBInspectable public var secondaryBtnTextAlignment: String = "left" {
        didSet {
            secondaryBtn.titleAlignment = secondaryBtnTextAlignment
        }
    }
    
    /// Secondary button on press event
    @IBAction func secondaryButtonPressed(_ sender: UIButton) {
        var buttonIdentifier: String?
        let secondaryButton = message?.elements?.buttons?[1]
        if let secondaryButtonAction = secondaryButton?.action {
            buttonIdentifier = secondaryButton?.id
            
            if let clickedUrl = secondaryButtonAction.data?.isEmpty == false ? secondaryButtonAction.data : secondaryButtonAction.type {
                IterableAPI.track(embeddedMessageClick: message!, buttonIdentifier: buttonIdentifier, clickedUrl: clickedUrl)
                IterableAPI.embeddedManager.handleEmbeddedClick(message: message!, buttonIdentifier: buttonIdentifier, clickedUrl: clickedUrl)
            }
        }
        
        //TODO: Delegate handling
//        if (iterableEmbeddedViewDelegate != nil) {
//            iterableEmbeddedViewDelegate.didPressSecondaryButton(button: sender, viewTag: self.tag, message: message)
//        }
//        else  { }
        
    }
    
    // MARK: Image
    /// Image Background Color
    @IBInspectable public var imgViewBackgroundColor: UIColor = UIColor.white {
        didSet {
            imgView.backgroundColor = imgViewBackgroundColor
        }
    }
    
    /// Image Corner Radius
    @IBInspectable public var imgViewCornerRadius: Double = 10 {
        didSet {
            imgView.layer.cornerRadius = imgViewCornerRadius
        }
    }
    
    /// Image Border Width
    @IBInspectable public var imgViewBorderWidth: Double = 0 {
        didSet {
            imgView.layer.borderWidth = imgViewBorderWidth
        }
    }
    
    /// Image Border Color
    @IBInspectable public var imgViewBorderColor: UIColor = UIColor.gray {
        didSet {
            imgView.layer.borderColor = imgViewBorderColor.cgColor
        }
    }
    
    /// Image Width
    @IBInspectable public var imgViewWidth:Double = 100 {
        didSet {
            imageViewWidthConstraint.constant = imgViewWidth
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    /// Image Height
    @IBInspectable public var imgViewHeight: Double = 100 {
        didSet {
            imageViewHeightConstraint.constant = imgViewHeight
            self.updateConstraintsIfNeeded()
            self.layoutIfNeeded()
        }
    }
    
    func widthOfString(string: String, font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (string as NSString).size(withAttributes: fontAttributes)
        return size.width
    }
    
    public func updateButtonConstraints() {
        let bothButtonsVisible = !primaryBtn.isHidden && !secondaryBtn.isHidden

        if !bothButtonsVisible {
            buttonStackView.axis = .horizontal
            horizontalButtonStackViewSpacer.isHidden = false
            return
        }

        let doesTextWrapInPrimary = doesTextWrapInButton(primaryBtn)
        let doesTextWrapInSecondary = doesTextWrapInButton(secondaryBtn)
        
        let shouldStackVertically = doesTextWrapInPrimary || doesTextWrapInSecondary

        buttonStackView.axis = shouldStackVertically ? .vertical : .horizontal
        horizontalButtonStackViewSpacer.isHidden = shouldStackVertically
    }

    private func doesTextWrapInButton(_ button: UIButton) -> Bool {
        guard let text = button.titleLabel?.text, let font = button.titleLabel?.font else {
            return false
        }

        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: button.bounds.height)
        let textRect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return textRect.width > button.bounds.width
    }

    
    public override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.updateButtonConstraints()
        }
    }
}

public class IterableEMButton: UIButton {
    private let maskLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @IBInspectable public var isRoundedSides: Bool = false {
        didSet {
            layoutSubviews()
        }
    }
    
    @IBInspectable var fontName: String = "HelveticaNeue-Bold" {
        didSet {
            updateAttributedTitle()
        }
    }

    @IBInspectable var fontSize: CGFloat = 14 {
        didSet {
            updateAttributedTitle()
        }
    }

    @IBInspectable var titleColor: UIColor = .white {
        didSet {
            updateAttributedTitle()
        }
    }

    @IBInspectable var titleText: String = "Button" {
        didSet {
            updateAttributedTitle()
        }
    }
    
    @IBInspectable var titleAlignment: String = "center" {
        didSet {
            updateAttributedTitle()
        }
    }
    
    var localTitleAlignment: NSTextAlignment = .center

    private func updateAttributedTitle() {
        let formattedAlignment = titleAlignment.lowercased().replacingOccurrences(of: " ", with: "")
        switch formattedAlignment {
            case "left":
                localTitleAlignment = .left
            case "center":
                localTitleAlignment = .center
            case "right":
                localTitleAlignment = .right
            default:
                localTitleAlignment = .center
        }
        
        let font = UIFont(name: self.fontName, size: self.fontSize) ?? .systemFont(ofSize: 20)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = localTitleAlignment
        let attributedTitle = NSAttributedString(string: self.titleText, attributes: [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: self.titleColor
        ])
        self.setAttributedTitle(attributedTitle, for: .normal)
        self.titleEdgeInsets = UIEdgeInsets.zero
        self.contentHorizontalAlignment = .fill

    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if isRoundedSides {
            layer.mask = maskLayer
            let path = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight],
                                    cornerRadii: CGSize(width: bounds.height / 2, height: bounds.height / 2))
            maskLayer.path = path.cgPath
        }
    }
}

public enum IterableEmbeddedViewType: String {
    case banner
    case card
    case notification
}


public class IterableEmbeddedViewConfig: NSObject {
    var backgroundColor: UIColor?
    var borderColor: UIColor?
    var borderWidth: CGFloat? = 1.0
    var borderCornerRadius: CGFloat? = 8.0
    var primaryBtnBackgroundColor: UIColor?
    var primaryBtnBorderColor: UIColor?
    var primaryBtnTextColor: UIColor?
    var secondaryBtnBackgroundColor: UIColor?
    var secondaryBtnBorderColor: UIColor?
    var secondaryBtnTextColor: UIColor?
    var titleTextColor: UIColor?
    var bodyTextColor: UIColor?
    
    public init(
         backgroundColor: UIColor? = nil,
         borderColor: UIColor? = nil,
         borderWidth: CGFloat? = 1.0,
         borderCornerRadius: CGFloat? = 8.0,
         primaryBtnBackgroundColor: UIColor? = nil,
         primaryBtnBorderColor: UIColor? = nil,
         primaryBtnTextColor: UIColor? = nil,
         secondaryBtnBackgroundColor: UIColor? = nil,
         secondaryBtnBorderColor: UIColor? = nil,
         secondaryBtnTextColor: UIColor? = nil,
         titleTextColor: UIColor? = nil,
         bodyTextColor: UIColor? = nil) {
        
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.borderCornerRadius = borderCornerRadius
        self.primaryBtnBackgroundColor = primaryBtnBackgroundColor
        self.primaryBtnBorderColor = primaryBtnBorderColor
        self.primaryBtnTextColor = primaryBtnTextColor
        self.secondaryBtnBackgroundColor = secondaryBtnBackgroundColor
        self.secondaryBtnBorderColor = secondaryBtnBorderColor
        self.secondaryBtnTextColor = secondaryBtnTextColor
        self.titleTextColor = titleTextColor
        self.bodyTextColor = bodyTextColor
    }
}
