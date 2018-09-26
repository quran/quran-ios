//
//  CompositeSupplementaryViewCreator.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/15/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents a supplementary view creator that manages other creators depending on the kind.
///
/// Usually this is used if you have multiple supplementary views (e.g. headers and footers)
/// and you need to have different views or different logic of configuration for the header than the footer.
/// Then you should use `CompositeSupplementaryViewCreator`.
///
/// For example:
/// ```swift
/// // define a composite creators.
/// let creator = CompositeSupplementaryViewCreator()
///
/// let headerCreator: SupplementaryViewCreator = <...>
/// let footerCreator: SupplementaryViewCreator = <...>
///
/// // add them to the composite creator.
/// creator.add(creator: headerCreator, forKind: UICollectionElementKindSectionHeader)
/// creator.add(creator: footerCreator, forKind: UICollectionElementKindSectionFooter)
///
/// // Then assign the composite creator to the data source.
/// dataSource.supplementaryViewCreator = creator
/// ```
open class CompositeSupplementaryViewCreator: NSObject, SupplementaryViewCreator {

    /// The list of child creators and their kind.
    open private(set) var creators: [String: SupplementaryViewCreator]

    /// Creates new instance with the passed creators.
    ///
    /// - parameter creators: The list of creators with their kind.
    public init(creators: [String: SupplementaryViewCreator] = [:]) {
        self.creators = creators
    }

    /// Creates new instance with header creator.
    ///
    /// - parameter headerCreator: The header creator.
    public convenience init(headerCreator: SupplementaryViewCreator) {
        self.init(creators: [headerKind: headerCreator])
    }

    /// Creates new instance with footer creator.
    ///
    /// - parameter footerCreator: The footer creator.
    public convenience init(footerCreator: SupplementaryViewCreator) {
        self.init(creators: [footerKind: footerCreator])
    }

    /// Creates new instance with header and footer creator.
    ///
    /// - parameter headerCreator: The header creator.
    /// - parameter footerCreator: The footer creator.
    public convenience init(headerCreator: SupplementaryViewCreator, footerCreator: SupplementaryViewCreator) {
        self.init(creators: [headerKind: headerCreator, footerKind: footerCreator])
    }

    /// Adds a new child creator for the specified kind.
    ///
    /// - parameter creator: The child creator that will handle the supplementary view calls for the specified kind.
    /// - parameter kind:    The kind which the creator will only operate for.
    open func add(creator: SupplementaryViewCreator, forKind kind: String) {
        creators[kind] = creator
    }

    /// Removes a creator for the passed kind.
    ///
    /// - parameter kind: The kind for which the creator is no longer needed.
    open func removeCreator(forKind kind: String) {
        creators.removeValue(forKey: kind)
    }

    /// Removes all creators.
    open func removeAllCreators() {
        creators.removeAll()
    }

    /// Gets the supplementary view creator for the passed kind.
    ///
    /// It crashes if there is no such creator.
    ///
    /// - parameter kind: The kind for which the creator needed.
    ///
    /// - returns: The supplementary view creator for the passed kind.
    open func creator(ofKind kind: String) -> SupplementaryViewCreator {
        let creator: SupplementaryViewCreator = cast(creators[kind], message: "Cannot find creator of kind '\(kind)'")
        return creator
    }

    /// Gets the supplementary view for the passed kind at the specified index path.
    ///
    /// It delegates the call to `creator(ofKind: kind)`.
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
        let viewCreator = creators[kind]
        return viewCreator?.collectionView(collectionView, viewOfKind: kind, at: indexPath)
    }

    /// Gets the size of the supplementary view for the passed kind at the specified index path.
    ///
    /// It delegates the call to `creator(ofKind: kind)`.
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
        let viewCreator = creators[kind]
        return viewCreator?.collectionView(collectionView, sizeForViewOfKind: kind, at: indexPath) ?? .zero
    }

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// It delegates the call to `creator(ofKind: kind)`.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open func collectionView(_ collectionView: GeneralCollectionView, willDisplayView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        let viewCreator = creators[kind]
        viewCreator?.collectionView(collectionView, willDisplayView: view, ofKind: kind, at: indexPath)
    }

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// It delegates the call to `creator(ofKind: kind)`.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open func collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        let viewCreator = creators[kind]
        viewCreator?.collectionView(collectionView, didEndDisplayingView: view, ofKind: kind, at: indexPath)
    }
}
