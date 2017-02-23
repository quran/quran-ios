//
//  ReusableSupplementaryView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/15/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the protocol for reusable supplementary view.
/// Subclasses can be used as return type for supplementary view of kind methods.
/// Currently we support `UITableViewHeaderFooterView` and `UICollectionReusableView`.
@objc public protocol ReusableSupplementaryView {
}

/// Make `UITableViewHeaderFooterView` reusable supplementary view.
extension UITableViewHeaderFooterView : ReusableSupplementaryView {
}

/// Make `UICollectionReusableView` reusable supplementary view.
extension UICollectionReusableView : ReusableSupplementaryView {
}
