//
//  SupplementaryViewCreator.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/15/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the protocol for types wanting to handle supplementary view creation and configurations.
/// Usually using `BasicSupplementaryViewCreator` or `CompsiteSupplentaryViewCreator` is enough.
/// But if you want to enhance the current architecture for new types, you should conform to this protocol.
///
/// You need to implement at least the following required functions:
/// - `collectionView(_, viewOfKind:, at:)`
/// - `collectionView(_, sizeForViewOfKind:, at:)`
public protocol SupplementaryViewCreator {

    /// Gets the supplementary view for the passed kind at the specified index path.
    ///
    /// For `UITableView`, it can be either `UICollectionElementKindSectionHeader` or
    /// `UICollectionElementKindSectionFooter` for header and footer views respectively.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is requested.
    ///
    /// - returns: The supplementary view dequeued and configured appropriately.
    func collectionView(_ collectionView: GeneralCollectionView, viewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView?

    /// Gets the size of the supplementary view for the passed kind at the specified index path.
    ///
    /// * For `UITableView` just supply the height width is don't care.
    /// * For `UICollectionViewFlowLayout` supply the height if it's vertical scrolling, or width if it's horizontal scrolling.
    /// * Specifying `CGSize.zero`, means don't display a supplementary view and `viewOfKind` will not be called.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view size is requested.
    ///
    /// - returns: The size of the supplementary view.
    func collectionView(_ collectionView: GeneralCollectionView, sizeForViewOfKind kind: String, at indexPath: IndexPath) -> CGSize

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    func collectionView(_ collectionView: GeneralCollectionView, willDisplayView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath)

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    func collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath)
}

extension SupplementaryViewCreator {

    /// Default implementation, does nothing.
    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    public func collectionView(_ collectionView: GeneralCollectionView, willDisplayView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // does nothing, making them optional
    }

    /// Default implementation, does nothing.
    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    public func collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        // does nothing, making them optional
    }
}
