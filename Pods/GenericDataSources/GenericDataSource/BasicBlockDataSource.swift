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
public class BasicBlockDataSource<ItemType, CellType: ReusableCell> : BasicDataSource <ItemType, CellType> {
    
    /// The configure closure type.
    public typealias ConfigureBlock = (item: ItemType, cell: CellType, indexPath: NSIndexPath) -> Void

    /// The configure block instance.
    private let configureBlock: ConfigureBlock
    
    /**
     Creates new instance of the basic block data source.
     
     - parameter reuseIdentifier: The reuse identifier for dequeuing the cells.
     - parameter configureBlock:  The configuration block for the cell.
     */
    public init(reuseIdentifier: String, configureBlock: ConfigureBlock) {
        self.configureBlock = configureBlock
        super.init(reuseIdentifier: reuseIdentifier)
    }

    /**
     Configure the cell. It calls the configure block to configure the cell.
     
     - parameter collectionView: The collection view that will show the cell.
     - parameter cell:           A general collection view object.
     - parameter item:           The item that is used in the configure operation.
     - parameter indexPath:      The index ptah of the cell under configuration.
     */
    public override func ds_collectionView(
        collectionView: GeneralCollectionView,
        configureCell cell: CellType,
        withItem item: ItemType,
        atIndexPath indexPath: NSIndexPath) {
        self.configureBlock(item: item, cell: cell, indexPath: indexPath)
    }
}
