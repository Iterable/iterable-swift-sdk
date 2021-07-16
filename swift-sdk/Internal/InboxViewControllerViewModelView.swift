//
//  Copyright © 2021 Iterable. All rights reserved.
//

import Foundation

protocol InboxViewControllerViewModelView: AnyObject {
    /// All these methods should be called on the main thread
    func onViewModelChanged(diffs: [RowDiff])
    func onImageLoaded(for indexPath: IndexPath)
    var currentlyVisibleRowIndexPaths: [IndexPath] { get }
}
