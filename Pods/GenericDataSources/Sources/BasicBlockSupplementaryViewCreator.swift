//
//  BasicBlockSupplementaryViewCreator.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/23/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the basic supplementary view creator subclass that does the configuration using a closure.
/// For more information see `BasicSupplementaryViewCreator`
open class BasicBlockSupplementaryViewCreator<ItemType, SupplementaryView: ReusableSupplementaryView>: BasicSupplementaryViewCreator<ItemType, SupplementaryView> {

    /// The configure closure type.
    public typealias ConfigureBlock = (ItemType, SupplementaryView, IndexPath) -> Void

    /// The configure block instance.
    private let configureBlock: ConfigureBlock

    /// Creates new instance with the passed reuse identfier, size and configure closure.
    /// If the `identifier` is not passed, then we will use `SupplementaryView.ds_reuseId` which is usually recommended.
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
    ///
    /// - parameter identifier:     The reuse identfier used to dequeue to the supplementary view.
    /// - parameter size:           Represents the size of the supplementary views.
    /// - parameter configureBlock: The configure block to bind views with items.
    public init(identifier: String = SupplementaryView.ds_reuseId, size: CGSize, configureBlock: @escaping ConfigureBlock) {
        self.configureBlock = configureBlock
        super.init(identifier: identifier, size: size)
    }

    /// Creates new instance with the passed reuse identfier and configure closure.
    /// If the `identifier` is not passed, then we will use `SupplementaryView.ds_reuseId` which is usually recommended.
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
    ///
    /// - parameter identifier:     The reuse identfier used to dequeue to the supplementary view.
    /// - parameter configureBlock: The configure block to bind views with items.
    public init(identifier: String = SupplementaryView.ds_reuseId, configureBlock: @escaping ConfigureBlock) {
        self.configureBlock = configureBlock
        super.init(identifier: identifier)
    }

    /// Configures the passed view by the passed item.
    ///
    /// This method just delegates the call to the `configureBlock` closure passed in the initializer.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that needs to be configured.
    /// - parameter item:           The item that will be used in configuring the supplementary view.
    /// - parameter indexPath:      The index path at which the supplementary view configuration is requested.
    override open func collectionView(_ collectionView: GeneralCollectionView, configure view: SupplementaryView, with item: ItemType, at indexPath: IndexPath) {
        self.configureBlock(item, view, indexPath)
    }
}
