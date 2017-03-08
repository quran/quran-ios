//
//  UIKitExtensions.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 9/16/15.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

extension UITableViewScrollPosition {
    init(scrollPosition: UICollectionViewScrollPosition) {
        if scrollPosition.contains(.top) {
            self = .top
        } else if scrollPosition.contains(.bottom) {
            self = .bottom
        } else if scrollPosition.contains(.centeredVertically) {
            self = .middle
        } else {
            self = .none
        }
    }
}

extension UITableView {

    /**
     Use this method to set up a table view with a data source.

     - parameter dataSource: The data source to set for the table view.
     */
    open func ds_useDataSource(_ dataSource: AbstractDataSource) {
        self.dataSource = dataSource
        self.delegate = dataSource
        dataSource.ds_reusableViewDelegate = self
    }
}

extension UICollectionView {

    /**
     Use this method to set up a collection view with a data source.

     - parameter dataSource: The data source to set for the table view.
     */
    open func ds_useDataSource(_ dataSource: AbstractDataSource) {
        self.dataSource = dataSource
        self.delegate = dataSource
        dataSource.ds_reusableViewDelegate = self
    }
}
