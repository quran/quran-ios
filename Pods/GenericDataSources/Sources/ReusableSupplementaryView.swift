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
@objc public protocol ReusableSupplementaryView: ReusableView {
}

/// Make `UITableViewHeaderFooterView` reusable supplementary view.
extension UITableViewHeaderFooterView : ReusableSupplementaryView {
}

/// Make `UICollectionReusableView` reusable supplementary view.
extension UICollectionReusableView : ReusableSupplementaryView {
}

extension UICollectionView {

    /// Registers a collection view supplementary view with a nib file.
    ///
    /// **IMPORTANT**:
    /// 1. The name of the nib file should be the same as the class name.
    /// 2. The reuseId used is the `ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicSupplementaryViewCreator` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - view: The supplementary view class.
    ///   - bundle: An optional bundle parameter. Specify it if the cell is not in the main bundle.
    ///   - kind: The kind of the supplementary view.
    open func ds_register(supplementaryViewNib view: UICollectionReusableView.Type, in bundle: Bundle? = nil, forKind kind: String) {
        register(UINib(nibName: view.ds_nibName, bundle: bundle), forSupplementaryViewOfKind: kind, withReuseIdentifier: view.ds_reuseId)
    }

    /// Registers a collection view supplementary view class.
    ///
    /// **IMPORTANT**:
    /// 1. The reuseId used is the `ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicSupplementaryViewCreator` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - view: The supplementary view class.
    ///   - kind: The kind of the supplementary view.
    open func ds_register(supplementaryViewClass view: UICollectionReusableView.Type, forKind kind: String) {
        register(view, forSupplementaryViewOfKind: kind, withReuseIdentifier: view.ds_reuseId)
    }
}

extension UITableView {

    /// Registers a table header footer view with a nib file.
    ///
    /// **IMPORTANT**:
    /// 1. The name of the nib file should be the same as the class name.
    /// 2. The reuseId used is the `ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicSupplementaryViewCreator` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - view: The supplementary view class.
    ///   - bundle: An optional bundle parameter. Specify it if the cell is not in the main bundle.
    open func ds_register(headerFooterNib view: UITableViewHeaderFooterView.Type, in bundle: Bundle? = nil) {
        register(UINib(nibName: view.ds_nibName, bundle: bundle), forHeaderFooterViewReuseIdentifier: view.ds_reuseId)
    }

    /// Registers a table header footer view class.
    ///
    /// **IMPORTANT**:
    /// 1. The reuseId used is the `CellType.ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicSupplementaryViewCreator` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - view: The supplementary view class.
    open func ds_register(headerFooterClass view: UITableViewHeaderFooterView.Type) {
        register(view, forHeaderFooterViewReuseIdentifier: view.ds_reuseId)
    }
}
