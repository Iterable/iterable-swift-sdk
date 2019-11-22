//
//  Created by Tapash Majumder on 4/11/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import UIKit

/// If you are creating your own Nib file you must
/// connect the outlets.
open class IterableInboxCell: UITableViewCell {
    /// A "dot" view showing that the message is unread
    @IBOutlet open weak var unreadCircleView: UIView?
    
    /// The title label
    @IBOutlet open weak var titleLbl: UILabel?
    
    /// The sub title label
    @IBOutlet open weak var subtitleLbl: UILabel?
    
    /// This shows the time when the message was created
    @IBOutlet open weak var createdAtLbl: UILabel?
    
    /// This is the container view for the icon image.
    /// You may or may not set it.
    /// Set this outlet if you have the icon inside a container view
    /// and you want the container to be set to hidden when icons are not
    /// present for the message.
    @IBOutlet open weak var iconContainerView: UIView?
    
    /// This is the icon image
    @IBOutlet open weak var iconImageView: UIImageView?
    
    open override func awakeFromNib() {
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
