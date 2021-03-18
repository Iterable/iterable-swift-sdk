//
//  Copyright © 2021 Iterable. All rights reserved.
//

import UIKit
import WebKit

private let reuseIdentifier = "Cell"

class IterableCardStreamViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Do any additional setup after loading the view.
//        if #available(iOS 14.0, *) {
//            let layoutConfig = UICollectionLayoutListConfiguration(appearance: .grouped)
//            let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
//
//            self.collectionView!.collectionViewLayout = listLayout
//        } else {
//            // Fallback on earlier versions
//        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numRows()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        let htmlString = viewModel.getHtmlForMessage(index: indexPath.row)
        
        let webView = IterableCardStreamViewController.createWebView()
        webView.set(position: ViewPosition(width: cell.contentView.frame.width,
                                           height: cell.contentView.frame.height,
                                           center: cell.contentView.center))
        webView.loadHTMLString(htmlString, baseURL: URL(string: ""))
        
        cell.contentView.addSubview(webView.view)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: - Private/Internal
    
    private static func createWebView() -> WebViewProtocol {
        let webView = WKWebView(frame: .zero)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        return webView as WebViewProtocol
    }
    
    private var viewModel = CardStreamViewControllerViewModel()
}

extension IterableCardStreamViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 500)
    }
}
