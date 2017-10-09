//
//  DataSourceSelector.swift
//  GenericDataSource
//
//  Created by Mohamed Ebrahim Mohamed Afifi on 3/30/17.
//  Copyright © 2017 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the data source selectors that can be optional.
/// Each case corresponds to a selector in the DataSource.
@objc public enum DataSourceSelector: Int {

    /// Represents the size selector.
    case size
    /*case shouldHighlight
    case didHighlight
    case didUnhighlight
    case shouldSelect
    case didSelect
    case shouldDeselect
    case didDeselect
    case supplementaryViewOfKind
    case sizeForSupplementaryViewOfKind
    case willDisplaySupplementaryView
    case didEndDisplayingSupplementaryView
    case canMove
    case move
    case willDisplayCell
    case didEndDisplayingCell*/

    /// Represents the can edit selector.
    case canEdit

    /// Represents the commit editing selector.
    case commitEditingStyle

    /// Represents the editing style selector.
    case editingStyle

    /// Represents the title for delete confirmation button selector.
    case titleForDeleteConfirmationButton

    /// Represents the edit actions selector.
    case editActions

    /// Represents the should indent while editing selector.
    case shouldIndentWhileEditing

    /// Represents the will begin selector.
    case willBeginEditing

    /// Represents the did end editing selector.
    case didEndEditing

    /// Represents the should show menu for item selector.
    case shouldShowMenuForItemAt

    /// Represents the can perform action selector.
    case canPerformAction

    /// Represents the perform action selector.
    case performAction

    /// Represents the can focus item at index selector.
    case canFocusItemAt

    /// Represents the should update focus in selector.
    case shouldUpdateFocusIn

    /// Represents the did update focus in selector.
    case didUpdateFocusIn

    /// Represents the index path for preferred focused in view selector.
    case indexPathForPreferredFocusedView
}

extension DataSourceSelector {

    /// Whether or not the selector requires all data sources to respond to it.
    /// Current implementation only `.size` requires all selectors and may change in the future.
    /// It's always recommended if you want to implement a selector in your `BasicDataSource` subclass.
    /// To do it in all classes that will be children of a `CompositeDataSource` or `SegmentedDataSource`.
    public var mustAllRespondsToIt: Bool {
        switch self {
        case .size: return true
        case .canEdit: return false
        case .commitEditingStyle: return false
        case .editingStyle: return false
        case .titleForDeleteConfirmationButton: return false
        case .editActions: return false
        case .shouldIndentWhileEditing: return false
        case .willBeginEditing: return false
        case .didEndEditing: return false
        case .shouldShowMenuForItemAt: return false
        case .canPerformAction: return false
        case .performAction: return false
        case .canFocusItemAt: return false
        case .shouldUpdateFocusIn: return false
        case .didUpdateFocusIn: return false
        case .indexPathForPreferredFocusedView: return false
        }
    }
}

let dataSourceSelectorToSelectorMapping: [DataSourceSelector: [Selector]] = {

    var mapping: [DataSourceSelector: [Selector]] =
        [.size: [
            #selector(UITableViewDelegate.tableView(_:heightForRowAt:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:sizeForItemAt:)),
            #selector(DataSource.ds_collectionView(_:sizeForItemAt:))
            ],
         .canEdit: [
            #selector(UITableViewDataSource.tableView(_:canEditRowAt:)),
            #selector(DataSource.ds_collectionView(_:canEditItemAt:))
            ],
         .commitEditingStyle: [
            #selector(UITableViewDataSource.tableView(_:commit:forRowAt:)),
            #selector(DataSource.ds_collectionView(_:commit:forItemAt:))
            ],
         .editingStyle: [
            #selector(UITableViewDelegate.tableView(_:editingStyleForRowAt:)),
            #selector(DataSource.ds_collectionView(_:editingStyleForItemAt:))
            ],
         .titleForDeleteConfirmationButton: [
            #selector(UITableViewDelegate.tableView(_:titleForDeleteConfirmationButtonForRowAt:)),
            #selector(DataSource.ds_collectionView(_:titleForDeleteConfirmationButtonForItemAt:))
            ],
         .editActions: [
            #selector(UITableViewDelegate.tableView(_:editActionsForRowAt:)),
            #selector(DataSource.ds_collectionView(_:editActionsForItemAt:))
            ],
         .shouldIndentWhileEditing: [
            #selector(UITableViewDelegate.tableView(_:shouldIndentWhileEditingRowAt:)),
            #selector(DataSource.ds_collectionView(_:shouldIndentWhileEditingItemAt:))
            ],
         .willBeginEditing: [
            #selector(UITableViewDelegate.tableView(_:willBeginEditingRowAt:)),
            #selector(DataSource.ds_collectionView(_:willBeginEditingItemAt:))
            ],
         .didEndEditing: [
            #selector(UITableViewDelegate.tableView(_:didEndEditingRowAt:)),
            #selector(DataSource.ds_collectionView(_:didEndEditingItemAt:))
            ],
         .shouldShowMenuForItemAt: [
            #selector(UITableViewDelegate.tableView(_:shouldShowMenuForRowAt:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:shouldShowMenuForItemAt:)),
            #selector(DataSource.ds_collectionView(_:shouldShowMenuForItemAt:))
            ],
         .canPerformAction: [
            #selector(UITableViewDelegate.tableView(_:canPerformAction:forRowAt:withSender:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:canPerformAction:forItemAt:withSender:)),
            #selector(DataSource.ds_collectionView(_:canPerformAction:forItemAt:withSender:))
            ],
         .performAction: [
            #selector(UITableViewDelegate.tableView(_:performAction:forRowAt:withSender:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:performAction:forItemAt:withSender:)),
            #selector(DataSource.ds_collectionView(_:performAction:forItemAt:withSender:))
            ]]

    if #available(iOS 9.0, *) {
        mapping[.canFocusItemAt] = [
            #selector(UITableViewDelegate.tableView(_:canFocusRowAt:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:canFocusItemAt:)),
            #selector(DataSource.ds_collectionView(_:canFocusItemAt:))
        ]
        mapping[.shouldUpdateFocusIn] = [
            #selector(UITableViewDelegate.tableView(_:shouldUpdateFocusIn:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:shouldUpdateFocusIn:)),
            #selector(DataSource.ds_collectionView(_:shouldUpdateFocusIn:))
        ]
        mapping[.didUpdateFocusIn] = [
            #selector(UITableViewDelegate.tableView(_:didUpdateFocusIn:with:)),
            #selector(UICollectionViewDelegateFlowLayout.collectionView(_:didUpdateFocusIn:with:)),
            #selector(DataSource.ds_collectionView(_:didUpdateFocusIn:with:))
        ]
        mapping[.indexPathForPreferredFocusedView] = [
            #selector(UITableViewDelegate.indexPathForPreferredFocusedView(in:)),
            #selector(UICollectionViewDelegateFlowLayout.indexPathForPreferredFocusedView(in:)),
            #selector(DataSource.ds_indexPathForPreferredFocusedView(in:))
        ]
    }
    return mapping
}()

let selectorToDataSourceSelectorMapping: [Selector: DataSourceSelector] = {
    var mapping: [Selector: DataSourceSelector] = [:]
    for (key, value) in dataSourceSelectorToSelectorMapping {
        for item in  value {
            precondition(mapping[item] == nil, "Use of selector \(item) multiple times")
            mapping[item] = key
        }
    }
    return mapping
}()
