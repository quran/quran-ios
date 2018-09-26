//
//  BasicSupplementaryViewCreator.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/15/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the basic supplementary view creator.
/// It manages supplementary views and items to bind to those views.
/// It also dequeues the supplementary views from the `UITableView`s and `UICollectionView`s automatically.
///
/// Usually for `UITableView` and `UICollectionViewFlowLayout`, you will be using `setSectionedItems` function.
///
/// **Note That**: The supplementary views can be associated with any index path.
/// Accordingly, the `items` property is an array of arrays, to get for example the item at `IndexPath(item: 1, section: 2)`
/// then we need to do that `items[2][1]`.
/// What about `UITableView` and `UICollectionViewFlowLayout` headers and footers, we have only 1 header per section.
/// For those cases `UICollectionViewFlowLayout` and our implementation for `UITableView` viewForHeader consider them
/// at `IndexPath(item: 0, section: x)` where x is the section number.
/// So we will be accessing the `items` property as items[section][0].
///
/// It's encouraged to subclass this class and implement:
/// - `collectionView(_, configure:, with:, at:)`
/// You can also implement `willDisplayView`, `didEndDisplayingView` if you want.
/// If you didn't set the `size` property to a non-nil value, you should impelement
/// - `collectionView(_, sizeForViewOfKind:, at:)`
///
/// If you don't want to subclass this class, then you can use `BasicBlockSupplementaryViewCreator` instead.
open class BasicSupplementaryViewCreator<ItemType, SupplementaryView: ReusableSupplementaryView>: NSObject, SupplementaryViewCreator {

    /// Represents the size of the supplementary views, if you want dynamic size, set this value to nil (which is default).
    /// Then implement `collectionView(_, sizeForViewOfKind:, at:)`
    open var size: CGSize?

    /// Represents the reuse identfier used to dequeue to the supplementary view.
    public let identifier: String

    /// Represents the list of items to be binded to the supplementary views.
    /// **Note That**: The supplementary views can be associated with any index path.
    /// Accordingly, this property is an array of arrays, to get for example the item at `IndexPath(item: 1, section: 2)`
    /// then we need to do that `items[2][1]`.
    /// What about `UITableView` and `UICollectionViewFlowLayout` headers and footers, we have only 1 header per section.
    /// For those cases `UICollectionViewFlowLayout` and our implementation for `UITableView` viewForHeader consider them
    /// at `IndexPath(item: 0, section: x)` where x is the section number.
    /// So we will be accessing the `items` property as items[section][0].
    open var items: [[ItemType]] = []

    /// Creates new instance with the passed reuse identifier and specific size for all views.
    /// - parameter identifier: The reuse identfier used to dequeue to the supplementary view.
    /// - parameter size:       Represents the size of the supplementary views.
    public init(identifier: String, size: CGSize) {
        self.identifier = identifier
        self.size = size
    }

    /// Creates new instance with the passed size and the `identifier will be `SupplementaryView.ds_reuseId` which is usually recommended.
    ///
    /// You can use one of the following recommended methods to register views:
    ///
    ///     extension UICollectionView {
    ///         func ds_register(supplementaryViewNib view: UICollectionReusableView.Type, in bundle: Bundle? = nil, forKind kind: String)
    ///         func ds_register(supplementaryViewClass view: UICollectionReusableView.Type, forKind kind: String)
    ///     }
    ///
    ///     extension UITableView {
    ///         func ds_register(headerFooterNib view: UITableViewHeaderFooterView.Type, in bundle: Bundle? = nil)
    ///         func ds_register(headerFooterNib view: UITableViewHeaderFooterView.Type)
    ///     }
    ///
    /// - parameter size:       Represents the size of the supplementary views.
    public init(size: CGSize) {
        self.identifier = SupplementaryView.ds_reuseId
        self.size = size
    }

    /// Creates new instance with the passed reuse identifier.
    /// - parameter identifier: The reuse identfier used to dequeue to the supplementary view.
    public init(identifier: String = SupplementaryView.ds_reuseId) {
        self.identifier = identifier
        self.size = nil
    }

    /// Creates new instance, the `identifier will be `SupplementaryView.ds_reuseId` which is usually recommended.
    ///
    /// You can use one of the following recommended methods to register views:
    ///
    ///     extension UICollectionView {
    ///         func ds_register(supplementaryViewNib view: UICollectionReusableView.Type, in bundle: Bundle? = nil, forKind kind: String)
    ///         func ds_register(supplementaryViewClass view: UICollectionReusableView.Type, forKind kind: String)
    ///     }
    ///
    ///     extension UITableView {
    ///         func ds_register(headerFooterNib view: UITableViewHeaderFooterView.Type, in bundle: Bundle? = nil)
    ///         func ds_register(headerFooterNib view: UITableViewHeaderFooterView.Type)
    ///     }
    public override init() {
        self.identifier = SupplementaryView.ds_reuseId
        self.size = nil
    }

    /// Sets the specified items array as sectioned items (i.e. mapping each item into an array with one element).
    /// - parameter sectionedItems: The array of items each item represents the item associated with a section.
    open func setSectionedItems(_ sectionedItems: [ItemType]) {
        items = sectionedItems.map { [$0] }
    }

    /// Gets the item at the specified index path.
    ///
    /// - parameter indexPath: The index path at which we will get the item.
    ///
    /// - returns: The item at the passed index path.
    open func item(at indexPath: IndexPath) -> ItemType {
        return items[indexPath.section][indexPath.item]
    }

    /// Gets the supplementary view for the passed kind at the specified index path.
    ///
    /// **Current implementation**:
    /// - Dequeues the view.
    /// - Get the item at the index path.
    /// - Delegate the configuring the view to `collectionView(_, configure:, with:, at:)`.
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
    open func collectionView(_ collectionView: GeneralCollectionView, viewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView? {
        let view = collectionView.ds_dequeueReusableSupplementaryView(ofKind: kind, withIdentifier: identifier, for: indexPath)

        let supplementaryView: SupplementaryView = cast(view, message: "Cannot cast view '\(view)' to type '\(SupplementaryView.self)'")
        self.collectionView(collectionView, configure: supplementaryView, with: item(at: indexPath), at: indexPath)
        return supplementaryView
    }

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
    open func collectionView(_ collectionView: GeneralCollectionView, sizeForViewOfKind kind: String, at indexPath: IndexPath) -> CGSize {
        let size: CGSize = cast(self.size, message: "sizeForViewOfKind called and `size` property is nil. Need to set it to non-nil value or override `sizeForViewOfKind` method and return a custom size.")
        return size
    }

    /// Configures the passed view by the passed item.
    ///
    /// This method **should be overriden** if you want to bind the item to the view.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that needs to be configured.
    /// - parameter item:           The item that will be used in configuring the supplementary view.
    /// - parameter indexPath:      The index path at which the supplementary view configuration is requested.
    open func collectionView(_ collectionView: GeneralCollectionView, configure view: SupplementaryView, with item: ItemType, at indexPath: IndexPath) {
        // does nothing, shall be overriden by subclasses
    }
}
