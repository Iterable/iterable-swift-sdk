//
//  IterableInboxCell.swift
//  swift-sdk
//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

/// If you are creating your own Xib file you must
/// connect the outlets.
open class IterableInboxCell: UITableViewCell {
    /// A "dot" view showing that the message is unread
    @IBOutlet weak open var unreadCircleView: UIView?
    
    /// The title label
    @IBOutlet weak open var titleLbl: UILabel?
    
    /// The sub title label
    @IBOutlet weak open var subtitleLbl: UILabel?
    
    /// This shows the time when the message was created
    @IBOutlet weak open var createdAtLbl: UILabel?
    
    /// This is the container view for the icon image.
    /// You may or may not set it.
    /// Set this outlet if you have the icon inside a container view
    /// and you want the container to be set to hidden when icons are not
    /// present for the message.
    @IBOutlet weak open var iconContainerView: UIView?
    
    /// This is the icon image
    @IBOutlet weak open var iconImageView: UIImageView?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    // override this to show unreadCircle color when highlighted
    // otherwise the background color is not correct.
    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let color = unreadCircleView?.backgroundColor
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            if let color = color {
                unreadCircleView?.backgroundColor = color
            }
        }
    }
}

