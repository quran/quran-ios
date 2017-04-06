//
//  DataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// The DataSource protocol is a general data source and delegate protocol for both a UITableViewDataSource/UITableViewDelegate and UICollectionViewDataSource/UICollectionViewDelegate and adopted by an object that mediates the application’s data model for a view object (e.g. `UITableView` or `UICollectionView`.
@objc public protocol DataSource : class {

    /// Asks the data source if it responds to a given selector.
    ///
    /// - Parameter selector: The selector to check if the instance repsonds to.
    /// - Returns: `true` if the instance responds to the passed selector, otherwise `false`.
    func ds_responds(to selector: DataSourceSelector) -> Bool

    /**
     Whether the data source provides the item size/height delegate calls for `tableView:heightForRowAtIndexPath:`
     or `collectionView:layout:sizeForItemAt:` or not.

     - returns: `true`, if the data source object will consume the delegate calls.
        `false` if the size/height information is provided to the `UITableView` using `rowHeight` and/or `estimatedRowHeight`
        or to the `UICollectionViewFlowLayout` using `itemSize` and/or `estimatedItemSize`.
     */
    @available(*, unavailable, renamed: "ds_responds(to:)", message: "with DataSourceSelector.size as parameter")
    func ds_shouldConsumeItemSizeDelegateCalls() -> Bool

    /**
     The resuable view delegate. Usually it is the UICollectionView/UITableView.
     This is provided in case a data source implementation would like to query or modify something in the view (e.g. inserting a section, etc.)
     */
    weak var ds_reusableViewDelegate: GeneralCollectionView? { get set }

    /**
     Asks the data source to return the number of sections.

     - returns: The number of sections.
     */
    func ds_numberOfSections() -> Int

    /**
     Asks the data source to return the number of items in a given section.

     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    func ds_numberOfItems(inSection section: Int) -> Int

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    @objc optional func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize

    // MARK: - Selection

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool

    /**
     Tells the delegate that the specified item was highlighted.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, didHighlightItemAt indexPath: IndexPath)

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, didUnhighlightItemAt indexPath: IndexPath)

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool

    /**
     Tells the delegate that the specified item was selected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath)

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool

    /**
     Tells the delegate that the specified item was deselected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    func ds_collectionView(_ collectionView: GeneralCollectionView, didDeselectItemAt indexPath: IndexPath)

    // MARK: - SupplementaryView

    /// Retrieves the supplementary view for the passed kind at the passed index path.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The supplementary view for the passed index path.
    func ds_collectionView(_ collectionView: GeneralCollectionView, supplementaryViewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView?

    /// Gets the size of supplementary view for the passed kind at the passed index path.
    ///
    /// * For `UITableView` just supply the height width is don't care.
    /// * For `UICollectionViewFlowLayout` supply the height if it's vertical scrolling, or width if it's horizontal scrolling.
    /// * Specifying `CGSize.zero`, means don't display a supplementary view and `viewOfKind` will not be called.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The size of the supplementary view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForSupplementaryViewOfKind kind: String, at indexPath: IndexPath) -> CGSize

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplaySupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath)

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingSupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath)

    // MARK: - Reordering

    /// Asks the delegate if the item can be moved for a reoder operation.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    func ds_collectionView(_ collectionView: GeneralCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool

    /// Performs the move operation of an item from `sourceIndexPath` to `destinationIndexPath`.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - sourceIndexPath: An index path locating the start position of the item in the view.
    ///   - destinationIndexPath: An index path locating the end position of the item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)

    // MARK: - Cell displaying

    /// The cell will is about to be displayed or moving into the visible area of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath)

    /// The cell will is already displayed and will be moving out of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplaying cell: ReusableCell, forItemAt indexPath: IndexPath)

    // MARK: - Copy/Paste

    /// Whether the copy/paste/etc. menu should be shown for the item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item should show the copy/paste/etc. menu, otherwise `false`.
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool

    /// Check whether an action/selector can be performed for a specific item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to check if it can be performed or not.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    func ds_collectionView(_ collectionView: GeneralCollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool

    /// Executes an action for a specific item with the passed sender.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to be executed.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    func ds_collectionView(_ collectionView: GeneralCollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?)

    // MARK: - Focus

    /// Whether or not the item can have focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can have focus, otherwise `false`.
    @available(iOS 9.0, *)
    func ds_collectionView(_ collectionView: GeneralCollectionView, canFocusItemAt indexPath: IndexPath) -> Bool

    /// Whether or not should we update the focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    @available(iOS 9.0, *)
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext) -> Bool

    /// The focus is has been updated.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    ///   - coordinator: The focus animation coordinator.
    @available(iOS 9.0, *)
    func ds_collectionView(_ collectionView: GeneralCollectionView, didUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator)

    /// Gets the index path of the preferred focused view.
    ///
    /// - Parameter collectionView: A general collection view object initiating the operation.
    @available(iOS 9.0, *)
    func ds_indexPathForPreferredFocusedView(in collectionView: GeneralCollectionView) -> IndexPath?

    // MARK: - Editing

    /// Check whether the item can be edited or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool

    /// Executes the editing operation for the item at the specified index pass.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - editingStyle: The
    ///   - indexPath: An index path locating an item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, commit editingStyle: UITableViewCellEditingStyle, forItemAt indexPath: IndexPath)

    /// Gets the editing style for an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The editing style.
    func ds_collectionView(_ collectionView: GeneralCollectionView, editingStyleForItemAt indexPath: IndexPath) -> UITableViewCellEditingStyle

    /// Gets the localized title for the delete button to show for editing an item (e.g. swipe to delete).
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The localized title string.
    func ds_collectionView(_ collectionView: GeneralCollectionView, titleForDeleteConfirmationButtonForItemAt indexPath: IndexPath) -> String?

    /// Gets the list of editing actions to use for editing an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The list of editing actions.
    func ds_collectionView(_ collectionView: GeneralCollectionView, editActionsForItemAt indexPath: IndexPath) -> [UITableViewRowAction]?

    /// Check whether to indent the item while editing or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be indented while editing, otherwise `false`.
    func ds_collectionView(_ collectionView: GeneralCollectionView, shouldIndentWhileEditingItemAt indexPath: IndexPath) -> Bool

    /// The item is about to enter into the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath)

    /// The item did leave the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath)
}
