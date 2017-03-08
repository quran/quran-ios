//
//  LocalDataSourceCollectionView.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 10/13/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

/// Represents the transformed collection view and index path.
/// Usually you get values of this struct by calling `transform(globalIndexPath:, globalCollectionView:)` on `CompositeDataSource`.
public struct LocalDataSourceCollectionView {

    /// Represents the local data source.
    public let dataSource: DataSource

    /// Represents the local collection view.
    public let collectionView: GeneralCollectionView

    /// Represents the local index path.
    public let indexPath: IndexPath
}
