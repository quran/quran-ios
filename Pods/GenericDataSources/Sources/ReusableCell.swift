//
//  ReusableCell.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 4/11/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 Represents the reusable cell protocol for all resuable cells mainliy `UITableViewCell` and `UICollectionViewCell`.
 This protocol is used to limit the use of the `BasicDataSource` generic type `CellType` to only for `UITableViewCell` and `UICollectionViewCell`.
 */
@objc public protocol ReusableCell: ReusableView {
}

/// Make `UITableViewCell` reusable cell.
extension UITableViewCell : ReusableCell {
}

/// Make `UICollectionViewCell` reusable cell.
extension UICollectionViewCell : ReusableCell {
}

extension GeneralCollectionView {

    /// Registers a cell with a nib file.
    ///
    /// **IMPORTANT**:
    /// 1. The name of the nib file should be the same as the cell name.
    /// 2. The reuseId used is the `CellType.ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicDataSource` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - cell: The cell class.
    ///   - bundle: An optional bundle parameter. Specify it if the cell is not in the main bundle.
    public func ds_register(cellNib cell: ReusableCell.Type, in bundle: Bundle? = nil) {
        ds_register(UINib(nibName: cell.ds_nibName, bundle: bundle), forCellWithReuseIdentifier: cell.ds_reuseId)
    }

    /// Registers a cell class.
    ///
    /// **IMPORTANT**:
    /// 1. The reuseId used is the `CellType.ds_reuseId`.
    ///
    /// You can use the default (parameterless) initializer of the `BasicDataSource` as it will be using the `ds_reuseId`.
    ///
    /// - Parameters:
    ///   - cell: The cell class.
    public func ds_register(cellClass cell: ReusableCell.Type) {
        ds_register(cell, forCellWithReuseIdentifier: cell.ds_reuseId)
    }
}
