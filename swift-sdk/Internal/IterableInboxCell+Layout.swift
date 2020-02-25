//
//  Note: We have to do the layout in code because Swift Package Manager does not support
//        resources yet. We can remove this once support for resoures is added.
//
//  Created by Tapash Majumder on 11/25/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import Foundation
import UIKit

extension IterableInboxCell {
    func doLayout() {
        let stack = createContainerStackview()
        let unreadContainerView = createUnreadContainerView()
        stack.addArrangedSubview(unreadContainerView)
        let titleLbl = IterableInboxCell.createTitleLabel()
        self.titleLbl = titleLbl
        let subtitleLbl = IterableInboxCell.createSubTitleLabel()
        self.subtitleLbl = subtitleLbl
        let createdAtLbl = IterableInboxCell.createCreatedAtLabel()
        self.createdAtLbl = createdAtLbl
        let middleStack = IterableInboxCell.createMiddleStackView(titleLbl: titleLbl, subtitleLbl: subtitleLbl, createdAtLbl: createdAtLbl)
        stack.addArrangedSubview(middleStack)
        
        let iconImageView = IterableInboxCell.createIconImageView()
        self.iconImageView = iconImageView
        let iconContainerView = IterableInboxCell.createIconContainerView(iconImageView: iconImageView)
        self.iconContainerView = iconContainerView
        stack.addArrangedSubview(iconContainerView)
    }
    
    func createContainerStackview() -> UIStackView {
        let stack = UIStackView()
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .top
        stack.distribution = .fill
        stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0).isActive = true
        stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8.0).isActive = true
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0).isActive = true
        stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5.0).isActive = true
        return stack
    }
    
    func createUnreadContainerView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let unreadCircleView = UIView()
        view.addSubview(unreadCircleView)
        view.widthAnchor.constraint(equalToConstant: 24.0).isActive = true
        unreadCircleView.translatesAutoresizingMaskIntoConstraints = false
        unreadCircleView.backgroundColor = UIColor(hex: "007AFF")
        unreadCircleView.layer.cornerRadius = 5.0
        unreadCircleView.widthAnchor.constraint(equalToConstant: 10.0).isActive = true
        unreadCircleView.heightAnchor.constraint(equalToConstant: 10.0).isActive = true
        unreadCircleView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        unreadCircleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 5.0).isActive = true
        self.unreadCircleView = unreadCircleView
        return view
    }
    
    private static func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 17.0)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        label.numberOfLines = 3
        return label
    }
    
    private static func createSubTitleLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13.0)
        label.textColor = UIColor.lightGray
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        label.numberOfLines = 3
        return label
    }
    
    private static func createCreatedAtLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = UIColor.lightGray
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        return label
    }
    
    private static func createMiddleStackView(titleLbl: UILabel, subtitleLbl: UILabel, createdAtLbl: UILabel) -> UIStackView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 8.0
        stack.addArrangedSubview(titleLbl)
        stack.addArrangedSubview(subtitleLbl)
        stack.addArrangedSubview(createdAtLbl)
        return stack
    }
    
    private static func createIconImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        
        return imageView
    }
    
    private static func createIconContainerView(iconImageView: UIImageView) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconImageView)
        let heightConstraint = view.widthAnchor.constraint(equalToConstant: 75.0)
        heightConstraint.priority = UILayoutPriority(250.0)
        heightConstraint.isActive = true
        iconImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.widthAnchor.constraint(greaterThanOrEqualTo: iconImageView.widthAnchor).isActive = true
        return view
    }
}
