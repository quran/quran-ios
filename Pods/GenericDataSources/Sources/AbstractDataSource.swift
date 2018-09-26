//
//  AbstractDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

/**
 The Base class for all data source implementations this class is responsible for concrete implementation of UITableViewDataSource/UITableViewDelegate and UICollectionViewDataSource/UICollectionViewDelegate/UICollectionViewDelegateFlowLayout by forwarding the calls to a coressponding DataSource implementation (e.g. implementation of both `tableView:cellForRowAtIndexPath:` and `collectionView:cellForItemAt:` will delegate the call to `ds_collectionView:cellForItemAt:`).

 On the other side, implementation of DataSource methods just `fatalError`. Subclasses are responsible for providing the implementation of the DataSource calls.

 Since this class is will be the delegate of the UITableView and UICollectionView. You can catch UIScrollViewDelegate methods by either subclass and implement the required method or provide use the property `scrollViewDelegate`. **Note that** this property is retained.
 */
open class AbstractDataSource: NSObject, DataSource, UITableViewDataSource, UICollectionViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout { // swiftlint:disable:this type_body_length

    /// Returns a string that describes the contents of the receiver for presentation in the debugger.
    open override var debugDescription: String {
        return description
    }

    /// Returns a string that describes the contents of the receiver.
    open override var description: String {
        let properties: [(String, Any?)] = [
            ("scrollViewDelegate", scrollViewDelegate),
            ("supplementaryViewCreator", supplementaryViewCreator)]
        return describe(self, properties: properties)
    }

    /// Represents the object responsible for creating and managing suppelmentary views (e.g. headers and footers).
    open var supplementaryViewCreator: SupplementaryViewCreator?

    /// Sets a header creator.
    ///
    /// - Parameter headerCreator: The header creator to set.
    open func set(headerCreator: SupplementaryViewCreator) {
        supplementaryViewCreator = CompositeSupplementaryViewCreator(headerCreator: headerCreator)
    }

    /// Sets a footer creator.
    ///
    /// - Parameter footerCreator: The footer creator to set.
    open func set(footerCreator: SupplementaryViewCreator) {
        supplementaryViewCreator = CompositeSupplementaryViewCreator(footerCreator: footerCreator)
    }

    /// Sets both header and footer creators.
    ///
    /// - Parameters:
    ///   - headerCreator: The header creator to set.
    ///   - footerCreator: The footer creator to set.
    open func set(headerCreator: SupplementaryViewCreator, footerCreator: SupplementaryViewCreator) {
        supplementaryViewCreator = CompositeSupplementaryViewCreator(headerCreator: headerCreator, footerCreator: footerCreator)
    }

    /**
     Represents the scroll view delegate property. Delegate calls of functions in UIScrollViewDelegate protocol are forwarded to this object.
     **Note that:** this object is retained.
     */
    open var scrollViewDelegate: UIScrollViewDelegate? = nil {
        willSet {
            precondition(self !== newValue, "You cannot set a DataSource as UIScrollViewDelegate. Instead just override the UIScrollViewDelegate methods.")
        }
    }

    /**
     Represents the reusable view delegate usually you treat it as if it's a UICollectionView/UITableView object. In most cases, you don't need to assign this property.
     But you will need to use it to query the view for data (e.g. number of sections, etc.)
     */
    open weak var ds_reusableViewDelegate: GeneralCollectionView?

    /**
     Initialize new instance of the AbstractDataSource `fatalError`. You should use one of its subclasses.
     */
    public override init() {
        let typeOf = AbstractDataSource.self
        guard type(of: self) != typeOf else {
            fatalError("\(typeOf) instances can not be created; create a subclass instance instead.")
        }
    }

    // MARK: respondsToSelector

    private func scrollViewDelegateCanHandleSelector(_ selector: Selector) -> Bool {
        if let scrollViewDelegate = scrollViewDelegate,
            isSelector(selector, belongsToProtocol: UIScrollViewDelegate.self) && scrollViewDelegate.responds(to: selector) {
            return true
        }
        return false
    }

    /**
     Returns a Boolean value that indicates whether the receiver implements or inherits a method that can respond to a specified message.
     true if the receiver implements or inherits a method that can respond to aSelector, otherwise false.

     - parameter selector: A selector that identifies a message.

     - returns: `true` if the receiver implements or inherits a method that can respond to aSelector, otherwise `false`.
     */
    open override func responds(to selector: Selector) -> Bool {

        // if one of our optional data source selectors
        if let dsSelector = selectorToDataSourceSelectorMapping[selector] {
            return ds_responds(to: dsSelector)
        }

        if scrollViewDelegateCanHandleSelector(selector) {
             return true
        }

        return super.responds(to: selector)
    }

    /// Asks the data source if it responds to a given selector.
    ///
    /// This method always returns `false`. Subclasses should handle the cases for non-default cases.
    ///
    /// - Parameter selector: The selector to check if the instance repsonds to.
    /// - Returns: `true` if the instance responds to the passed selector, otherwise `false`.
    open func ds_responds(to selector: DataSourceSelector) -> Bool {
        // by default it is false.
        return false
    }

    /**
     Returns the object to which unrecognized messages should first be directed.
     The object to which unrecognized messages should first be directed.

     - parameter selector: A selector for a method that the receiver does not implement.

     - returns: The object to which unrecognized messages should first be directed.
     */
    open override func forwardingTarget(for selector: Selector) -> Any? {
        if scrollViewDelegateCanHandleSelector(selector) {
            return scrollViewDelegate
        }
        return super.forwardingTarget(for: selector)
    }

    // MARK: - DataSource

    // MARK: UITableViewDataSource

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func numberOfSections(in tableView: UITableView) -> Int {
        return ds_numberOfSections()
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ds_numberOfSections() <= section {
            return 0
        }
        return ds_numberOfItems(inSection: section)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ds_collectionView(tableView, cellForItemAt: indexPath)
        return cast(cell)
    }

    // MARK: - UICollectionViewDataSource

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ds_numberOfItems(inSection: section)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return ds_numberOfSections()
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = ds_collectionView(collectionView, cellForItemAt: indexPath)
        return cast(cell)
    }

    // MARK: - UITableViewDelegate

    // MARK: Selection

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, shouldHighlightItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didHighlightItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didUnhighlightItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didSelectItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return ds_collectionView(tableView, shouldSelectItemAt: indexPath) ? indexPath : nil
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didDeselectItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return ds_collectionView(tableView, shouldDeselectItemAt: indexPath) ? indexPath : nil
    }

    // MARK: Size

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ds_collectionView(tableView, sizeForItemAt: indexPath).height
    }

    // MARK: - UICollectionViewDelegate

    // MARK: Selection

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldHighlightItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didHighlightItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didUnhighlightItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didSelectItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldSelectItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldDeselectItemAt: indexPath)
    }

    // MARK: Size

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ds_collectionView(collectionView, sizeForItemAt: indexPath)
    }

    // MARK: - Data Source

    /**
     Asks the data source to return the number of sections.

     **IMPORTANT**: Should be implemented by subclasses.

     - returns: The number of sections.
     */
    open func ds_numberOfSections() -> Int {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source to return the number of items in a given section.

     **IMPORTANT**: Should be implemented by subclasses.

     - parameter section: An index number identifying a section.

     - returns: The number of items in a given section
     */
    open func ds_numberOfItems(inSection section: Int) -> Int {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.

     **IMPORTANT**: Should be implemented by subclasses.

     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, cellForItemAt indexPath: IndexPath) -> ReusableCell {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.

     **IMPORTANT**: Should be implemented by subclasses.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForItemAt indexPath: IndexPath) -> CGSize {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    /**
     Tells the delegate that the specified item was highlighted.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didHighlightItemAt indexPath: IndexPath) {
        // does nothing
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        // does nothing
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be selected or `false` if it should not.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    /**
     Tells the delegate that the specified item was selected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didSelectItemAt indexPath: IndexPath) {
        // does nothing
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.

     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    /**
     Tells the delegate that the specified item was deselected.

     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didDeselectItemAt indexPath: IndexPath) {
        // does nothing
    }

    // MARK: - Header/Footer

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = ds_collectionView(tableView, supplementaryViewOfKind: headerKind, at: IndexPath(item: 0, section: section))
        return optionalCast(view)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return ds_collectionView(tableView, sizeForSupplementaryViewOfKind: headerKind, at: IndexPath(item: 0, section: section)).height
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let castedView: UITableViewHeaderFooterView = cast(view)
        ds_collectionView(tableView, willDisplaySupplementaryView: castedView, ofKind: headerKind, at: IndexPath(item: 0, section: section))
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        let castedView: UITableViewHeaderFooterView = cast(view)
        ds_collectionView(tableView, didEndDisplayingSupplementaryView: castedView, ofKind: headerKind, at: IndexPath(item: 0, section: section))
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = ds_collectionView(tableView, supplementaryViewOfKind: footerKind, at: IndexPath(item: 0, section: section))
        return optionalCast(view)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return ds_collectionView(tableView, sizeForSupplementaryViewOfKind: footerKind, at: IndexPath(item: 0, section: section)).height
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let castedView: UITableViewHeaderFooterView = cast(view)
        ds_collectionView(tableView, willDisplaySupplementaryView: castedView, ofKind: footerKind, at: IndexPath(item: 0, section: section))
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        let castedView: UITableViewHeaderFooterView = cast(view)
        ds_collectionView(tableView, didEndDisplayingSupplementaryView: castedView, ofKind: footerKind, at: IndexPath(item: 0, section: section))
    }

    // MARK: UICollectionView

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = ds_collectionView(collectionView, supplementaryViewOfKind: kind, at: indexPath)
        return cast(view)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: headerKind, at: IndexPath(item: 0, section: section))
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        ds_collectionView(collectionView, willDisplaySupplementaryView: view, ofKind: elementKind, at: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        ds_collectionView(collectionView, didEndDisplayingSupplementaryView: view, ofKind: elementKind, at: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return ds_collectionView(collectionView, sizeForSupplementaryViewOfKind: footerKind, at: IndexPath(item: 0, section: section))
    }

    // MARK: DataSource

    /// Retrieves the supplementary view for the passed kind at the passed index path.
    ///
    /// Note: You don't need to subclass this method, usually, you just specifiy a `supplementaryViewCreator` that will be responsible for this operation.
    ///
    /// - Parameters:
    ///   - collectionView: The collectionView requesting the supplementary view.
    ///   - kind: The kind of the supplementary view.
    ///   - indexPath: The indexPath at which the supplementary view is requested.
    /// - Returns: The supplementary view for the passed index path.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, supplementaryViewOfKind kind: String, at indexPath: IndexPath) -> ReusableSupplementaryView? {
        return supplementaryViewCreator?.collectionView(collectionView, viewOfKind: kind, at: indexPath)
    }

    /// Gets the size of supplementary view for the passed kind at the passed index path.
    ///
    /// Note: You don't need to subclass this method, usually, you just specifiy a `supplementaryViewCreator` that will be responsible for this operation.
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
    open func ds_collectionView(_ collectionView: GeneralCollectionView, sizeForSupplementaryViewOfKind kind: String, at indexPath: IndexPath) -> CGSize {
        return supplementaryViewCreator?.collectionView(collectionView, sizeForViewOfKind: kind, at: indexPath) ?? .zero
    }

    /// Supplementary view is about to be displayed. Called exactly before the supplementary view is displayed.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplaySupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        supplementaryViewCreator?.collectionView(collectionView, willDisplayView: view, ofKind: kind, at: indexPath)
    }

    /// Supplementary view has been displayed and user scrolled it out of the screen.
    /// Called exactly after the supplementary view is scrolled out of the screen.
    ///
    /// - parameter collectionView: The general collection view requesting the index path.
    /// - parameter view:           The supplementary view that will  be displayed.
    /// - parameter kind:           The kind of the supplementary view. For `UITableView`, it can be either
    ///                             `UICollectionElementKindSectionHeader` or `UICollectionElementKindSectionFooter` for
    ///                             header and footer views respectively.
    /// - parameter indexPath:      The index path at which the supplementary view is.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplayingSupplementaryView view: ReusableSupplementaryView, ofKind kind: String, at indexPath: IndexPath) {
        supplementaryViewCreator?.collectionView(collectionView, didEndDisplayingView: view, ofKind: kind, at: indexPath)
    }

    // MARK: - Reordering

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, canMoveItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return ds_collectionView(tableView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
    }

    // MARK: UICollectionView

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, canMoveItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        return ds_collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
    }

    // MARK: DataSource

    /// Asks the delegate if the item can be moved for a reoder operation.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /// Performs the move operation of an item from `sourceIndexPath` to `destinationIndexPath`.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - sourceIndexPath: An index path locating the start position of the item in the view.
    ///   - destinationIndexPath: An index path locating the end position of the item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // does nothing
    }

    // MARK: - Cell displaying

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, willDisplay: cell, forItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    // MARK: UICollectionView

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    // MARK: DataSource

    /// The cell will is about to be displayed or moving into the visible area of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        // does nothing
    }

    /// The cell will is already displayed and will be moving out of the screen.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - cell: The cell that will be displayed
    ///   - indexPath: An index path locating an item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didEndDisplaying cell: ReusableCell, forItemAt indexPath: IndexPath) {
        // does nothing
    }

    // MARK: - Copy/Paste

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, shouldShowMenuForItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return ds_collectionView(tableView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        return ds_collectionView(tableView, performAction: action, forItemAt: indexPath, withSender: sender)
    }

    // MARK: UICollectionView

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return ds_collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        return ds_collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
    }

    // MARK: DataSource

    /// Whether the copy/paste/etc. menu should be shown for the item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item should show the copy/paste/etc. menu, otherwise `false`.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /// Check whether an action/selector can be performed for a specific item or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to check if it can be performed or not.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    /// Executes an action for a specific item with the passed sender.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - action: The action that is requested to be executed.
    ///   - indexPath: An index path locating an item in the view.
    ///   - sender: The sender of the action.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        // does nothing
    }

    // MARK: - Focus

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, canFocusItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func tableView(_ tableView: UITableView, shouldUpdateFocusIn context: UITableViewFocusUpdateContext) -> Bool {
        return ds_collectionView(tableView, shouldUpdateFocusIn: context)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        return ds_collectionView(tableView, didUpdateFocusIn: context, with: coordinator)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        return ds_indexPathForPreferredFocusedView(in: tableView)
    }

    // MARK: UICollectionView

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, canFocusItemAt: indexPath)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        return ds_collectionView(collectionView, shouldUpdateFocusIn: context)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        return ds_collectionView(collectionView, didUpdateFocusIn: context, with: coordinator)
    }

    /// `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
    @available(iOS 9.0, *)
    open func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return ds_indexPathForPreferredFocusedView(in: collectionView)
    }

    // MARK: DataSource

    /// Whether or not the item can have focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can have focus, otherwise `false`.
    @available(iOS 9.0, *)
    open func ds_collectionView(_ collectionView: GeneralCollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    /// Whether or not should we update the focus.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    @available(iOS 9.0, *)
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext) -> Bool {
        return false
    }

    /// The focus is has been updated.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - context: The focus context.
    ///   - coordinator: The focus animation coordinator.
    @available(iOS 9.0, *)
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didUpdateFocusIn context: GeneralCollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // does nothing
    }

    /// Gets the index path of the preferred focused view.
    ///
    /// - Parameter collectionView: A general collection view object initiating the operation.
    @available(iOS 9.0, *)
    open func ds_indexPathForPreferredFocusedView(in collectionView: GeneralCollectionView) -> IndexPath? {
        return nil
    }

    // MARK: - Editing

    // MARK: UITableView

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, canEditItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, commit: editingStyle, forItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return ds_collectionView(tableView, editingStyleForItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return ds_collectionView(tableView, titleForDeleteConfirmationButtonForItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return ds_collectionView(tableView, editActionsForItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, shouldIndentWhileEditingItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, willBeginEditingItemAt: indexPath)
    }

    /// `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
    open func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if let indexPath = indexPath {
            ds_collectionView(tableView, didEndEditingItemAt: indexPath)
        }
    }

    // MARK: DataSource

    /// Check whether the item can be edited or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be moved, otherwise `false`.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    /// Executes the editing operation for the item at the specified index pass.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - editingStyle: The
    ///   - indexPath: An index path locating an item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, commit editingStyle: UITableViewCell.EditingStyle, forItemAt indexPath: IndexPath) {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /// Gets the editing style for an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The editing style.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, editingStyleForItemAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return ds_collectionView(collectionView, canEditItemAt: indexPath) ? .delete : .none
    }

    /// Gets the localized title for the delete button to show for editing an item (e.g. swipe to delete).
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The localized title string.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, titleForDeleteConfirmationButtonForItemAt indexPath: IndexPath) -> String? {
        return nil
    }

    /// Gets the list of editing actions to use for editing an item.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: The list of editing actions.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, editActionsForItemAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return nil
    }

    /// Check whether to indent the item while editing or not.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    /// - Returns: `true` if the item can be indented while editing, otherwise `false`.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, shouldIndentWhileEditingItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    /// The item is about to enter into the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, willBeginEditingItemAt indexPath: IndexPath) {
    }

    /// The item did leave the editing mode.
    ///
    /// - Parameters:
    ///   - collectionView: A general collection view object initiating the operation.
    ///   - indexPath: An index path locating an item in the view.
    open func ds_collectionView(_ collectionView: GeneralCollectionView, didEndEditingItemAt indexPath: IndexPath) {
    }
}
