//
//  BasicBlockDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/27/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/**
 A basic data source class that configures the cells with a closure.
 */
open class BasicBlockDataSource<ItemType, CellType: ReusableCell> : BasicDataSource <ItemType, CellType> {

    /// The configure closure type.
    public typealias ConfigureBlock = (ItemType, CellType, IndexPath) -> Void

    /// The configure block instance.
    private let configureBlock: ConfigureBlock

    /**
     Creates new instance of the basic block data source with configure block and reuse id.

     - parameter reuseIdentifier: The reuse identifier for dequeuing the cells.
     - parameter configureBlock:  The configuration block for the cell.
     */
    public init(reuseIdentifier: String, configureBlock: @escaping ConfigureBlock) {
        self.configureBlock = configureBlock
        super.init(reuseIdentifier: reuseIdentifier)
    }

    /// Creates new instance of the basic block data source with just the configure block.
    /// Providing a way to use the default reuse Id (`Cell.ds_reuseId`) which represents the class name.
    /// Usually (**99.99% of the times**) we register the cell once. So a unique name would be the `Cell.ds_reuseId`.
    ///
    /// You can use one of the following recommended methods to register cells:
    ///
    ///     extension GeneralCollectionView {
    ///         func ds_register(cellNib cell: ReusableCell.Type, in bundle: Bundle? = nil)
    ///         func ds_register(cellClass cell: ReusableCell.Type)
    ///     }
    public init(configureBlock: @escaping ConfigureBlock) {
        self.configureBlock = configureBlock
        super.init()
    }

    /**
     Configure the cell. It calls the configure block to configure the cell.

     - parameter collectionView: The collection view that will show the cell.
     - parameter cell:           A general collection view object.
     - parameter item:           The item that is used in the configure operation.
     - parameter indexPath:      The index ptah of the cell under configuration.
     */
    open override func ds_collectionView(
        _ collectionView: GeneralCollectionView,
        configure cell: CellType,
        with item: ItemType,
        at indexPath: IndexPath) {
        self.configureBlock(item, cell, indexPath)
    }
}
