//
//  BasicDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

/**
 The basic data source class that is responsible for managing a set of similar type cells that binds
 to items (an array of items of type `ItemType`) of the similar type and rendered as one section.

 This class similar to all other data source classes can be used with `UICollectionView` or `UITableView`.
 But if used with `UICollectionView`, `CellType` should be of type `UICollectionViewCell` and
 if used with `UITableView`, `CellType` should be of type `UITableViewCell`.

 For sizing cells, you can use `itemSize` for `UICollectionView` and `itemHeight` for `UITableView`. Or if you want to specify a custom size, you can override `ds_collectionView(_:sizeForItemAt:)`, **but needs** to set `useDelegateForItemSize` to `true` otherwise the overriden method will not be called.
 */
open class BasicDataSource<ItemType, CellType: ReusableCell> : AbstractDataSource, BasicDataSourceRepresentable {

    /// Returns a string that describes the contents of the receiver.
    open override var description: String {
        let properties: [(String, Any?)] = [
            ("itemSize", itemSizeSet ? itemSize : nil),
            ("scrollViewDelegate", scrollViewDelegate),
            ("supplementaryViewCreator", supplementaryViewCreator)]
        return describe(self, properties: properties)
    }

    private var itemSizeSet: Bool = false

    /// The size of the cell. Usually used with a `UICollectionView`.
    /// When setting a value to it. It will set `useDelegateForItemSize` to `true`.
    open var itemSize: CGSize = CGSize.zero {
        didSet {
            itemSizeSet = true
        }
    }

    /// The height of the cell. Usually used with a `UITableView`.
    /// When setting a value to it. It will set `useDelegateForItemSize` to `true`.
    open var itemHeight: CGFloat {
        set {
            itemSize = CGSize(width: 1, height: newValue)
        }
        get {
            return itemSize.height
        }
    }

    /**
     Specify whether to use delegate method `ds_collectionView(_:sizeForItemAt:)` for getting
     size of the cells or not. Usually you need to set it to true if you want to override
     `ds_collectionView(_:sizeForItemAt:)`. If you will use `itemSize` or `itemHeight`,
     then those properties sets this property to `true`.
     */
    @available(*, unavailable, message: "Now, we can detect if you implemented sizeForItemAt or not")
    open var useDelegateForItemSize: Bool = false

    /// Represents the underlying data source which is `self`.
    open var dataSource: AbstractDataSource { return self }

    /// A closure to be called when the items array has been updated.
    open var onItemsUpdated: (([ItemType]) -> Void)?

    /**
     Represents the list of items managed by this basic data source.
     */
    open var items: [ItemType] = [] {
        didSet {
            selectionHandler?.dataSourceItemsModified(self)
            onItemsUpdated?(items)
        }
    }

    /// Represents the reuse identifier to use for dequeuing cells from the `UICollectionView`/`UITableView`.
    public let reuseIdentifier: String

    /// Represents the selection handler used for delegating calls to selection handler.
    private var selectionHandler: AnyDataSourceSelectionHandler<ItemType, CellType>?

    /**
     Sets the selection handler used for delegating selection, highlighting calls to it.

     - parameter selectionHandler: The new selection handler instance to be set.
     This parameter will be retained.
     */
    open func setSelectionHandler<H: DataSourceSelectionHandler>(_ selectionHandler: H) where H.CellType == CellType, H.ItemType == ItemType {
        self.selectionHandler = selectionHandler.anyDataSourceSelectionHandler()
    }

    /**
     Creates new instance with the passed reuse identifer.

     - parameter reuseIdentifier: the reuse identifier to use for dequeuing cells from the `UICollectionView`/`UITableView`
     */
    public init(reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
    }

    /// Providing a way to use the default reuse Id (`Cell.ds_reuseId`) which represents the class name.
    /// Usually (**99.99% of the times**) we register the cell once. So a unique name would be the `Cell.ds_reuseId`.
    ///
    /// You can use one of the following recommended methods to register cells:
    ///
    ///     extension GeneralCollectionView {
    ///         func ds_register(cellNib cell: ReusableCell.Type, in bundle: Bundle? = nil)
    ///         func ds_register(cellClass cell: ReusableCell.Type)
    ///     }
    public override init() {
        self.reuseIdentifier = CellType.ds_reuseId
    }

    // MARK: - DataSource

    /// Asks the data source if it responds to a given selector.
    ///
    /// This method returns `true` if the optional selector is overwritten by subclasses. Otherwise, it returns false.
    ///
    /// - Parameter selector: The selector to check if the instance repsonds to.
    /// - Returns: `true` if the instance responds to the passed selector, otherwise `false`.
    open override func ds_responds(to selector: DataSourceSelector) -> Bool {
        if selector == .size && itemSizeSet {
            return true
        }

        // we always define last one as DataSource selector.
        let theSelector = dataSourceSelectorToSelectorMapping[selector]!.last!
        // check if the subclass implemented the selector, always return true
        return subclassHasDifferentImplmentation(type: BasicDataSource.self, selector: theSelector)
    }

    // MARK: Cell

    /**
     Asks the data source to return the number of sections.

     - returns: The number of sections. Always returns `1`.
     */
    open override func ds_numberOfSections() -> Int {
        return 1
    }

    /**
     Asks the data source to return the number of items in a given section.

     - parameter section: An index number identifying a section.

     - returns: The number of items in the `items` array.
     */
    open override func ds_numberOfItems(inSection section: Int) -> Int {
        return items.count
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     This method dequeues a cell with the `reuseIdentifier` passed in the initializer.
     Then give the user the ability to configure it with calling `ds_collectionView(_:configureCell:withItem:atIndexPath)`.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell {

        let cell = ds_collectionView(collectionView, dequeueCellForItemAt: indexPath)
        let theItem: ItemType = item(at: indexPath)
        ds_collectionView(collectionView, configure: cell, with: theItem, at: indexPath)
        selectionHandler?.dataSource(self, collectionView: collectionView, configure: cell, with: theItem, at: indexPath)
        return cell
    }

    /**
     Dequeues a cell at certain index path from a collection view.

     - parameter collectionView: The collection view that is used for the dequeuing operation.
     - parameter indexPath:      The index path of the cell.

     - returns: The dequeued cell.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, dequeueCellForItemAt indexPath: IndexPath) -> CellType {

        let cell = collectionView.ds_dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let castedCell: CellType = cast(cell, message: "cell: \(cell) with reuse identifier '\(reuseIdentifier)' expected to be of type \(CellType.self).")
        return castedCell
    }

    /**
     Configures the cell after dequeuing it with the passed item. Subclasses should override this method to bind the item to the cell.

     This method does nothing.

     - parameter collectionView: The collection view that will show the cell.
     - parameter cell:           A general collection view object.
     - parameter item:           The item that is used in the configure operation.
     - parameter indexPath:      The index ptah of the cell under configuration.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, configure cell: CellType, with item: ItemType, at indexPath: IndexPath) {
        // does nothing
        // should be overriden by subclasses
    }

    // MARK: Size

    /**
     Gets the size for an item at certain index path. The default implementation uses the value specified by `itemSize` or `itemHeight`.

     Override it if you want to have custom behavior.

     - parameter collectionView: A general collection view object requesting the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the item at certain index path.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }

    // MARK: Selection

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, shouldHighlightItemAt: indexPath)
        }
        return selectionHandler.dataSource(self, collectionView: collectionView, shouldHighlightItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was highlighted.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, didHighlightItemAt: indexPath)
        }
        selectionHandler.dataSource(self, collectionView: collectionView, didHighlightItemAt: indexPath)
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, didUnhighlightItemAt: indexPath)
        }
        selectionHandler.dataSource(self, collectionView: collectionView, didUnhighlightItemAt: indexPath)
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, shouldSelectItemAt: indexPath)
        }
        return selectionHandler.dataSource(self, collectionView: collectionView, shouldSelectItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was selected.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, didSelectItemAt: indexPath)
        }
        selectionHandler.dataSource(self, collectionView: collectionView, didSelectItemAt: indexPath)
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, shouldDeselectItemAt: indexPath)
        }
        return selectionHandler.dataSource(self, collectionView: collectionView, shouldDeselectItemAt: indexPath)
    }

    /**
     Tells the delegate that the specified item was deselected.

     Current implementation forwards the call to the `selectionHandler`.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open override func ds_collectionView(_ collectionView: GeneralCollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let selectionHandler = selectionHandler else {
            return super.ds_collectionView(collectionView, didDeselectItemAt: indexPath)
        }
        selectionHandler.dataSource(self, collectionView: collectionView, didDeselectItemAt: indexPath)
    }
}
