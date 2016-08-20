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
    #selector(UITableViewDelegate.tableView(_:heightForRowAtIndexPath:)),
    #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAtIndexPath:)),
    #selector(DataSource.ds_collectionView(_:sizeForItemAtIndexPath:))
]

/**
 The Base class for all data source implementations this class is responsible for concrete implementation of UITableViewDataSource/UITableViewDelegate and UICollectionViewDataSource/UICollectionViewDelegate/UICollectionViewDelegateFlowLayout by forwarding the calls to a coressponding DataSource implementation (e.g. implementation of both `tableView:cellForRowAtIndexPath:` and `collectionView:cellForItemAtIndexPath:` will delegate the call to `ds_collectionView:cellForItemAtIndexPath:`).
 
 On the other side, implementation of DataSource methods just `fatalError`. Subclasses are responsible for providing the implementation of the DataSource calls.
 
 Since this class is will be the delegate of the UITableView and UICollectionView. You can catch UIScrollViewDelegate methods by either subclass and implement the required method or provide use the property `scrollViewDelegate`. **Note that** this property is retained.
 */
public class AbstractDataSource : NSObject, DataSource, UITableViewDataSource, UICollectionViewDataSource, UITableViewDelegate, UICollectionViewDelegateFlowLayout {

    /**
     Represents the scroll view delegate property. Delegate calls of functions in UIScrollViewDelegate protocol are forwarded to this object.
     **Note that:** this object is retained.
     */
    public var scrollViewDelegate: UIScrollViewDelegate? = nil {
        willSet {
            precondition(self !== newValue, "You cannot set a DataSource as UIScrollViewDelegate. Instead just override the UIScrollViewDelegate methods.")
        }
    }

    /**
     Represents the reusable view delegate usually you treat it as if it's a UICollectionView/UITableView object. In most cases, you don't need to assign this property.
     But you will need to use it to query the view for data (e.g. number of sections, etc.)
     */
    public weak var ds_reusableViewDelegate: GeneralCollectionView? = nil

    /**
     Initialize new instance of the AbstractDataSource `fatalError`. You should use one of its subclasses.
     */
    public override init() {
        let type = AbstractDataSource.self
        guard self.dynamicType != type else {
            fatalError("\(type) instances can not be created; create a subclass instance instead.")
        }
    }

    // MARK: respondsToSelector

    private func scrollViewDelegateCanHandleSelector(selector: Selector) -> Bool {
        if let scrollViewDelegate = scrollViewDelegate
            where isSelector(selector, belongsToProtocol: UIScrollViewDelegate.self) &&
                scrollViewDelegate.respondsToSelector(selector) {
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
    public override func respondsToSelector(selector: Selector) -> Bool {

        if sizeSelectors.contains(selector) {
            return ds_shouldConsumeItemSizeDelegateCalls()
        }

        if scrollViewDelegateCanHandleSelector(selector) {
             return true
        }

        return super.respondsToSelector(selector)
    }
    
    /**
     Returns the object to which unrecognized messages should first be directed.
     The object to which unrecognized messages should first be directed.

     - parameter selector: A selector for a method that the receiver does not implement.
     
     - returns: The object to which unrecognized messages should first be directed.
     */
    public override func forwardingTargetForSelector(selector: Selector) -> AnyObject? {
        if scrollViewDelegateCanHandleSelector(selector) {
            return scrollViewDelegate
        }
        return super.forwardingTargetForSelector(selector)
    }

    // MARK:- DataSource

    // MARK: UITableViewDataSource

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return ds_numberOfSections()
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ds_numberOfSections() <= section {
            return 0
        }
        return ds_numberOfItems(inSection: section)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = ds_collectionView(tableView, cellForItemAtIndexPath: indexPath)
        guard let castedCell = cell as? UITableViewCell else {
            fatalError("Couldn't cast cell '\(cell)' to UITableViewCell")
        }
        return castedCell
    }

    // MARK:- UICollectionViewDataSource

    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ds_numberOfItems(inSection: section)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return ds_numberOfSections()
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            let cell: ReusableCell = ds_collectionView(collectionView, cellForItemAtIndexPath: indexPath)
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
    public func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return ds_collectionView(tableView, shouldHighlightItemAtIndexPath: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(tableView, didHighlightItemAtIndexPath: indexPath)
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(tableView, didUnhighlightItemAtIndexPath: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(tableView, didSelectItemAtIndexPath: indexPath)
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return ds_collectionView(tableView, shouldSelectItemAtIndexPath: indexPath) ? indexPath : nil
    }
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(tableView, didDeselectItemAtIndexPath: indexPath)
    }

    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return ds_collectionView(tableView, shouldDeselectItemAtIndexPath: indexPath) ? indexPath : nil
    }
    
    // MARK: Size
    
    /**
     `UITableViewDataSource`/`UITableViewDelegate` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ds_collectionView(tableView, sizeForItemAtIndexPath: indexPath).height
    }

    // MARK:- UICollectionViewDelegate
    
    // MARK: Selection

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldHighlightItemAtIndexPath: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(collectionView, didHighlightItemAtIndexPath: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(collectionView, didUnhighlightItemAtIndexPath: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(collectionView, didSelectItemAtIndexPath: indexPath)
    }
    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldSelectItemAtIndexPath: indexPath)
    }
    
    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        return ds_collectionView(collectionView, didDeselectItemAtIndexPath: indexPath)
    }

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return ds_collectionView(collectionView, shouldDeselectItemAtIndexPath: indexPath)
    }

    // MARK: Size

    /**
     `UICollectionViewDataSource`/`UICollectionViewDelegateFlowLayout` implementations forwards calls to the corresponding `DataSource` methods.
     */
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return ds_collectionView(collectionView, sizeForItemAtIndexPath: indexPath)
    }

    /**
     Whether the data source provides the item size/height delegate calls for `tableView:heightForRowAtIndexPath:`
     or `collectionView:layout:sizeForItemAtIndexPath:` or not.
     
     - returns: `true`, if the data source object will consume the delegate calls.
     `false` if the size/height information is provided to the `UITableView` using `rowHeight` and/or `estimatedRowHeight`
     or to the `UICollectionViewFlowLayout` using `itemSize` and/or `estimatedItemSize`.
     */
    public func ds_shouldConsumeItemSizeDelegateCalls() -> Bool {
        return false
    }

    // MARK:- Data Source

    /**
     Asks the data source to return the number of sections.
     
     **IMPORTANT**: Should be implemented by subclasses.
     
     - returns: The number of sections.
     */
    public func ds_numberOfSections() -> Int {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source to return the number of items in a given section.
     
     **IMPORTANT**: Should be implemented by subclasses.
     
     - parameter section: An index number identifying a section.
     
     - returns: The number of items in a given section
     */
    public func ds_numberOfItems(inSection section: Int) -> Int {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source for a cell to insert in a particular location of the general collection view.
     
     **IMPORTANT**: Should be implemented by subclasses.
     
     - parameter collectionView: A general collection view object requesting the cell.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: An object conforming to ReusableCell that the view can use for the specified item.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> ReusableCell {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }

    /**
     Asks the data source for the size of a cell in a particular location of the general collection view.
     
     **IMPORTANT**: Should be implemented by subclasses.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: The size of the cell in a given location. For `UITableView`, the width is ignored.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        fatalError("\(self): \(#function) Should be implemented by subclasses")
    }
    
    /**
     Asks the delegate if the specified item should be highlighted.
     `true` if the item should be highlighted or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be highlighted or `false` if it should not.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    /**
     Tells the delegate that the specified item was highlighted.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        // does nothing
    }

    /**
     Tells the delegate that the highlight was removed from the item at the specified index path.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        // does nothing
    }

    /**
     Asks the delegate if the specified item should be selected.
     `true` if the item should be selected or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be selected or `false` if it should not.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    /**
     Tells the delegate that the specified item was selected.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // does nothing
    }

    /**
     Asks the delegate if the specified item should be deselected.
     `true` if the item should be deselected or `false` if it should not.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     
     - returns: `true` if the item should be deselected or `false` if it should not.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    /**
     Tells the delegate that the specified item was deselected.
     
     - parameter collectionView: A general collection view object initiating the operation.
     - parameter indexPath:      An index path locating an item in the view.
     */
    public func ds_collectionView(collectionView: GeneralCollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        // does nothing
    }
}

private func isSelector(selector: Selector, belongsToProtocol aProtocol: Protocol) -> Bool {
    return isSelector(selector, belongsToProtocol: aProtocol, isRequired: true, isInstance: true) ||
        isSelector(selector, belongsToProtocol: aProtocol, isRequired: false, isInstance: true)
}

private func isSelector(selector: Selector, belongsToProtocol aProtocol: Protocol, isRequired: Bool, isInstance: Bool) -> Bool {
    let method = protocol_getMethodDescription(aProtocol, selector, isRequired, isInstance)
    return method.types != nil
}