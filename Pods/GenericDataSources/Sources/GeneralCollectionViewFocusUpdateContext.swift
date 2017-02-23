//
//  GeneralCollectionViewFocusUpdateContext.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 11/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@objc public protocol FocusUpdateContext: NSObjectProtocol {

    /// The item that was focused before the update, i.e. where focus is updating from. May be nil if no item was focused, such as when focus is initially set.
    @available(iOS 10.0, *)
    weak var previouslyFocusedItem: UIFocusItem? { get }

    /// The item that is focused after the update, i.e. where focus is updating to. May be nil if no item is being focused, meaning focus is being lost.
    @available(iOS 10.0, *)
    weak var nextFocusedItem: UIFocusItem? { get }

    /// The view that was focused before the update. May be nil if no view was focused, such as when setting initial focus.
    /// If previouslyFocusedItem is not a view, this returns that item's containing view, otherwise they are equal.
    weak var previouslyFocusedView: UIView? { get }

    /// The view that will be focused after the update. May be nil if no view will be focused.
    /// If nextFocusedItem is not a view, this returns that item's containing view, otherwise they are equal.
    weak var nextFocusedView: UIView? { get }

    /// The focus heading in which the update is occuring.
    var focusHeading: UIFocusHeading { get }
}

@available(iOS 9.0, *)
extension UIFocusUpdateContext: FocusUpdateContext { }

@available(iOS 9.0, *)
@objc public protocol GeneralCollectionViewFocusUpdateContext: FocusUpdateContext {

    var previouslyFocusedIndexPath: IndexPath? { get }

    var nextFocusedIndexPath: IndexPath? { get }
}

@available(iOS 9.0, *)
extension UICollectionViewFocusUpdateContext: GeneralCollectionViewFocusUpdateContext { }

@available(iOS 9.0, *)
extension UITableViewFocusUpdateContext: GeneralCollectionViewFocusUpdateContext { }
