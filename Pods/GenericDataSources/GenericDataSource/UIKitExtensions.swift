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
        if scrollPosition.contains(.Top) {
            self = .Top
        } else if scrollPosition.contains(.Bottom) {
            self = .Bottom
        } else if scrollPosition.contains(.CenteredVertically) {
            self = .Middle
        } else {
            self = .None
        }
    }
}

extension UITableView {
    
    /**
     Use this method to set up a table view with a data source.
     
     - parameter dataSource: The data source to set for the table view.
     */
    public func ds_useDataSource(dataSource: AbstractDataSource) {
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
    public func ds_useDataSource(dataSource: AbstractDataSource) {
        self.dataSource = dataSource
        self.delegate = dataSource
        dataSource.ds_reusableViewDelegate = self
    }
}
