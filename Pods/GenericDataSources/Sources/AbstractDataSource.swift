//
//  AbstractDataSource.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import UIKit

/// Represents the selectors for querying a height/size of a cell.
let sizeSelectors: [Selector] = [
    #selector(UITableViewDelegate.tableView(_:heightForRowAt:)),
    #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:)),
    #selector(DataSource.ds_collectionView(_:sizeForItemAt:))
]

/**
 The Base class for all data source implementations this class is responsible for concrete implementation of UITableViewDataSource/UITableViewDelegate and UICollectionViewDataSource/UICollectionViewDelegate/UICollectionViewDelegateFlowLayout by forwarding the calls to a coressponding DataSource implementation (e.g. implementation of both `tableView:cellForRowAtIndexPath:` and `collectionView:cellForItemAt:` will delegate the call to `ds_collectionView:cellForItemAt:`).
 
 On the other side, implementation of DataSource methods just `fatalError`. Subclasses are responsible for providing the implementation of the DataSource calls.
 
 Since this class is will be the delegate of the UITableView and UICollectionView. You can catch UIScrollViewDelegate methods by either subclass and implement the required method or provide use the property `scrollViewDelegate`. **Note that** this property is retained.
 */
open class AbstractDataSource : NSObject, DataSource, UITableViewDataSource, UICollectionViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {

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
    open weak var ds_reusableViewDelegate: GeneralCollectionView? = nil

    /**
     Initialize new instance of the AbstractDataSource `fatalError`. You should use one of its subclasses.
     */
    public override init() {
        let type = AbstractDataSource.self
        guard type(of: self) != type else {
            fatalError("\(type) instances can not be created; create a subclass instance instead.")
        }
    }

    // MARK: respondsToSelector

    fileprivate func scrollViewDelegateCanHandleSelector(_ selector: Selector) -> Bool {
        if let scrollViewDelegate = scrollViewDelegate
            , isSelector(selector, belongsToProtocol: UIScrollViewDelegate.self) &&
                scrollViewDelegate.responds(to: selector) {
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

        if sizeSelectors.contains(selector) {
            return ds_shouldConsumeItemSizeDelegateCalls()
        }

        if scrollViewDelegateCanHandleSelector(selector) {
             return true
        }

        return super.responds(to: selector)
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

    // MARK:- DataSource

    // MARK: UITableViewDataSource

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func numberOfSections(in tableView: UITableView) -> Int {
        return ds_numberOfSections()
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ds_numberOfSections() <= section {
            return 0
        }
        return ds_numberOfItems(inSection: section)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ds_collectionView(tableView, cellForItemAt: indexPath)
        guard let castedCell = cell as? UITableViewCell else {
            fatalError("Couldn't cast cell '\(cell)' to UITableViewCell")
        }
        return castedCell
    }

    // MARK:- UICollectionViewDataSource

    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ds_numberOfItems(inSection: section)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return ds_numberOfSections()
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell: ReusableCell = ds_collectionView(collectionView, cellForItemAt: indexPath)
            guard let castedCell = cell as? UICollectionViewCell else {
                fatalError("Couldn't cast cell '\(cell)' to UICollectionViewCell")
            }
            return castedCell
    }

    // MARK:- UITableViewDelegate
    
    // MARK: Selection

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(tableView, shouldHighlightItemAt: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didHighlightItemAt: indexPath)
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didUnhighlightItemAt: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didSelectItemAt: indexPath)
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return ds_collectionView(tableView, shouldSelectItemAt: indexPath) ? indexPath : nil
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        return ds_collectionView(tableView, didDeselectItemAt: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return ds_collectionView(tableView, shouldDeselectItemAt: indexPath) ? indexPath : nil
    }
    
    // MARK: Size
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ds_collectionView(tableView, sizeForItemAt: indexPath).height
    }

    // MARK:- UICollectionViewDelegate
    
    // MARK: Selection

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldHighlightItemAt: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didHighlightItemAt: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didUnhighlightItemAt: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldSelectItemAt: indexPath)
    }
    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        return ds_collectionView(collectionView, didDeselectItemAt: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldDeselectItemAt: indexPath)
    }

    // MARK: Size

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ds_collectionView(collectionView, sizeForItemAt: indexPath)
    }

    /**
     Whether the data source provides the item size/height delegate calls for `tableView:heightForRowAtIndexPath:`
     or `collectionView:layout:sizeForItemAt:` or not.
     
     - returns: `true`, if the data source object will consume the delegate calls.
     `false` if the size/height information is provided to the `UITableView` using `rowHeight` and/or `estimatedRowHeight`
     or to the `UICollectionViewFlowLayout` using `itemSize` and/or `estimatedItemSize`.
     */
    open func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return false
    }

    // MARK:- Data Source

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
}

private func isSelector(_ selector: Selector, belongsToProtocol aProtocol: Protocol) -> Bool {
    return isSelector(selector, belongsToProtocol: aProtocol, isRequired: true, isInstance: true) ||
        isSelector(selector, belongsToProtocol: aProtocol, isRequired: false, isInstance: true)
}

private func isSelector(_ selector: Selector, belongsToProtocol aProtocol: Protocol, isRequired: Bool, isInstance: Bool) -> Bool {
    let method = protocol_getMethodDescription(aProtocol, selector, isRequired, isInstance)
    return method.types != nil
}
