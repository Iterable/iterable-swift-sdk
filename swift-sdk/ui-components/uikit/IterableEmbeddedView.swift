//
//  IterableEmbeddedView.swift
//  Fiterable
//
//  Created by Vivek on 25/05/23.
//

import Foundation
import UIKit

@IBDesignable
public class IterableEmbeddedView:UIView {
    
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
    @IBOutlet var cardImageTopConstraint: NSLayoutConstraint!
    @IBOutlet var titleToTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak public var imageViewWidthConstraint:NSLayoutConstraint!
    @IBOutlet weak public var imageViewHeightConstraint:NSLayoutConstraint!
    

    // MARK: Embedded Message Content
    /// Title
    private var embeddedMessageTitle: String? = "Placeholding Title" {
        didSet {
            if let title = embeddedMessageTitle {
                labelTitle.text = title
                labelTitle.font = UIFont.boldSystemFont(ofSize: 16.0)
                labelTitle.isHidden = false
            } else {
                labelTitle.isHidden = true
            }
        }
    }
    
    public var EMimage: UIImage? = nil
    
    /// Description
    var embeddedMessageBody: String? = "Placeholding Description" {
        didSet {
            if let body = embeddedMessageBody {
                labelDescription.text = body
                labelDescription.font = UIFont.systemFont(ofSize: 14.0)
                labelDescription.isHidden = false
            } else {
                labelDescription.isHidden = true
            }
        }
    }
    
    /// Primary Button Text
    var embeddedMessagePrimaryBtnTitle: String? = "Placeholding BTN 1" {
        didSet {
            if let btn = embeddedMessagePrimaryBtnTitle {
                primaryBtn.titleText = btn
                primaryBtn.isHidden = false
            } else {
                primaryBtn.isHidden = true
            }
        }
    }
    
    /// Secondary Button Text
    var embeddedMessageSecondaryBtnTitle: String? = "Placeholding BTN 2" {
        didSet {
            if let btn = embeddedMessageSecondaryBtnTitle {
                secondaryBtn.titleText = btn
                secondaryBtn.isHidden = false
            } else {
                secondaryBtn.isHidden = true
            }
        }
    }
    
    /// Associated Embedded Message
    public var message: IterableEmbeddedMessage? = nil
    
    // MARK: OOTB View IBInspectables
    /// OOTB View Background Color
    public var ootbViewBackgroundColor: UIColor = UIColor.white {
        didSet {
            self.backgroundColor = UIColor.clear
            self.innerContentView.backgroundColor = ootbViewBackgroundColor
        }
    }

    /// OOTB View Border Color
    public var ootbViewBorderColor: UIColor = UIColor(red: 0.88, green: 0.87, blue: 0.87, alpha: 1.00) {
        didSet {
            self.layer.borderColor = ootbViewBorderColor.cgColor
        }
    }
    
    /// OOTB View Border Width
    public var ootbViewBorderWidth: CGFloat = 1.0 {
        didSet {
            self.layer.borderWidth = ootbViewBorderWidth
        }
    }

    /// OOTB View Corner Radius
    public var ootbViewCornerRadius: CGFloat = 8.0 {
        didSet {
            self.layer.cornerRadius = ootbViewCornerRadius
            contentView.layer.cornerRadius = ootbViewCornerRadius
            innerContentView.layer.cornerRadius = ootbViewCornerRadius
        }
    }

    // MARK: Primary Button
    /// Primary button background color.
    public var primaryBtnColor: UIColor = UIColor.purple {
        didSet {
           primaryBtn.backgroundColor = primaryBtnColor
        }
    }
    
    /// Primary button text color.
    public var primaryBtnTextColor: UIColor = UIColor.white {
        didSet {
            primaryBtn.titleColor = primaryBtnTextColor
        }
    }

    // MARK: Second Button
    /// Secondary button background color.
    public var secondaryBtnColor: UIColor = UIColor.clear {
        didSet {
            secondaryBtn.backgroundColor = secondaryBtnColor
        }
    }

    /// Secondary button text color.
    public var secondaryBtnTextColor: UIColor = UIColor.black {
        didSet {
            secondaryBtn.titleColor = secondaryBtnTextColor
        }
    }

    /// Title Text Color
    public var titleTextColor: UIColor = UIColor.black {
        didSet {
            labelTitle.textColor = titleTextColor
        }
    }

    /// Body Text Color
    public var bodyTextColor: UIColor = UIColor.darkGray {
        didSet {
            labelDescription.textColor = bodyTextColor
        }
    }
    
    // MARK: IterableEmbeddedView init method
     /// IterableEmbeddedView init method
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    public init(message: IterableEmbeddedMessage, viewType: IterableEmbeddedViewType, config: IterableEmbeddedViewConfig?) {
        super.init(frame: CGRect.zero)
        xibSetup()
        configure(message: message, viewType: viewType, config: config)
    }

    func xibSetup() {
        self.contentView = self.loadViewFromNib()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.innerContentView.clipsToBounds = true
        self.addSubview(self.contentView)
            
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
        
        buttonStackView.heightAnchor.constraint(equalToConstant: primaryBtn.frame.height).isActive = true
        labelTitle.heightAnchor.constraint(equalToConstant: labelTitle.frame.height * 2).isActive = true
        labelDescription.heightAnchor.constraint(equalToConstant: labelDescription.frame.height).isActive = true
    }
    
    func loadViewFromNib() -> UIView? {
        var nib: UINib
        #if COCOAPODS
            let bundle = Bundle(path: Bundle(for: IterableEmbeddedView.self).path(forResource: "Resources", ofType: "bundle")!)
            nib = UINib(nibName: "IterableEmbeddedView", bundle: bundle)
        #else
            #if SWIFT_PACKAGE
                nib = UINib(nibName: "IterableEmbeddedView", bundle: Bundle.module)
            #else
                nib = UINib(nibName: "IterableEmbeddedView", bundle: Bundle.main)
            #endif
        #endif

        let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
        self.clipsToBounds = false
        return view
    }

    
    public func configure(message: IterableEmbeddedMessage, viewType: IterableEmbeddedViewType, config: IterableEmbeddedViewConfig?) {
        
        self.message = message
        
        let primaryBtnText = message.elements?.buttons?.first?.title
        let secondaryBtnText = message.elements?.buttons?.count ?? 0 > 1 ? message.elements?.buttons?[1].title : nil
        
        self.embeddedMessagePrimaryBtnTitle = primaryBtnText
        self.embeddedMessageSecondaryBtnTitle = secondaryBtnText
        self.embeddedMessageTitle = message.elements?.title
        self.embeddedMessageBody = message.elements?.body
        
        if let imageUrl = message.elements?.mediaUrl {
            if let url = URL(string: imageUrl) {
                loadImage(from: url, withViewType: viewType)
                self.EMimage?.accessibilityLabel = message.elements?.mediaUrlCaption
            }
        }
        
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
        
        ootbViewBackgroundColor = config?.backgroundColor ?? defaultBackgroundColor
        ootbViewBorderColor = config?.borderColor ?? defaultBorderColor
        ootbViewBorderWidth = config?.borderWidth ?? 1.0
        ootbViewCornerRadius = config?.borderCornerRadius ?? 8.0
        primaryBtnColor = config?.primaryBtnBackgroundColor ?? defaultPrimaryBtnColor
        primaryBtnTextColor = config?.primaryBtnTextColor ?? defaultPrimaryBtnTextColor
        secondaryBtnColor = config?.secondaryBtnBackgroundColor ?? defaultSecondaryBtnColor
        secondaryBtnTextColor = config?.secondaryBtnTextColor ?? defaultSecondaryBtnTextColor
        titleTextColor = config?.titleTextColor ?? defaultTitleTextColor
        bodyTextColor = config?.bodyTextColor ?? defaultBodyTextColor
    }
        
    private func loadViewType(viewType: IterableEmbeddedViewType) {
        switch viewType {
            case .card:
                imgView.isHidden = true
                let shouldShowCardImageView = EMimage != nil
                if shouldShowCardImageView {
                    // Show cardImageView
                    cardImageView.image = EMimage
                    cardImageView.isHidden = false
                    cardImageTopConstraint.isActive = true
                    titleToTopConstraint.isActive = false
                    titleToTopConstraint?.isActive = false
                } else {
                    // Hide cardImageView and deactivate its constraints
                    cardImageView.isHidden = true
                    cardImageTopConstraint.isActive = false
                    titleToTopConstraint.isActive = true
                    titleToTopConstraint?.isActive = true

                    // Remove cardImageView from its superview and release it
                    cardImageView.removeFromSuperview()
                    cardImageView = nil
                }
            case .banner:
                imgView.isHidden = EMimage == nil
                imgView.isHidden = self.EMimage == nil
                imgView.image = EMimage
                if !imgView.isHidden {
                    imgView.widthAnchor.constraint(equalToConstant: 100).isActive = true
                }
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
                cardImageTopConstraint?.isActive = false
                titleToTopConstraint?.isActive = true
            case .notification:
                imgView.isHidden = true
                cardImageView.isHidden = true
                cardImageTopConstraint.isActive = false
                titleToTopConstraint.isActive = true
                cardImageTopConstraint?.isActive = false
                titleToTopConstraint?.isActive = true
        }
    }
    
    private func loadImage(from url: URL, withViewType viewType: IterableEmbeddedViewType) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_5_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = request.allHTTPHeaderFields

        let session = URLSession(configuration: config)

        session.dataTask(with: request) { [weak self] (data, _, _) in
            
            if let imageData = data {
                self?.EMimage = UIImage(data: imageData)
            }
            
            DispatchQueue.main.async {
                self?.loadViewType(viewType: viewType)
            }

        }.resume()
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
    }
    
    public var viewConfig: IterableEmbeddedViewConfig?
    
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
    }
    
    func widthOfString(string: String, font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (string as NSString).size(withAttributes: fontAttributes)
        return size.width
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
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

    @IBInspectable public var isRoundedSides: Bool = true {
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
        
        titleLabel?.numberOfLines = 1
        titleLabel?.lineBreakMode = .byTruncatingTail
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
    var borderWidth: CGFloat?
    var borderCornerRadius: CGFloat?
    var primaryBtnBackgroundColor: UIColor?
    var primaryBtnTextColor: UIColor?
    var secondaryBtnBackgroundColor: UIColor?
    var secondaryBtnTextColor: UIColor?
    var titleTextColor: UIColor?
    var bodyTextColor: UIColor?
    
    public init(
         backgroundColor: UIColor? = nil,
         borderColor: UIColor? = nil,
         borderWidth: CGFloat? = 1.0,
         borderCornerRadius: CGFloat? = 8.0,
         primaryBtnBackgroundColor: UIColor? = nil,
         primaryBtnTextColor: UIColor? = nil,
         secondaryBtnBackgroundColor: UIColor? = nil,
         secondaryBtnTextColor: UIColor? = nil,
         titleTextColor: UIColor? = nil,
         bodyTextColor: UIColor? = nil) {
        
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.borderCornerRadius = borderCornerRadius
        self.primaryBtnBackgroundColor = primaryBtnBackgroundColor
        self.primaryBtnTextColor = primaryBtnTextColor
        self.secondaryBtnBackgroundColor = secondaryBtnBackgroundColor
        self.secondaryBtnTextColor = secondaryBtnTextColor
        self.titleTextColor = titleTextColor
        self.bodyTextColor = bodyTextColor
    }
}
