//
//  _SingleSectionDataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class _SingleSectionDataSourcesCollection: NSObject, _DataSourcesCollection {

    private var itemsCount: Int = 0

    private var globalItemToMappings: [Int: _SingleSectionMapping] = [:]

    var mappings: _MappingCollection = _MappingCollection()

    unowned let parentDataSource: CompositeDataSource

    init(parentDataSource: CompositeDataSource) {
        self.parentDataSource = parentDataSource
    }

    func createMapping(for dataSource: DataSource) -> _DataSourcesCollectionMapping {
        return _SingleSectionMapping(dataSource: dataSource)
    }

    func updateMappings() {

        // reset
        var count = 0
        globalItemToMappings.removeAll(keepingCapacity: true)

        for mapping in mappings.array {
            let mapping: _SingleSectionMapping = cast(mapping, message: "Mappings for \(type(of: self)) should be of type \(_SingleSectionMapping.self)")

            let newItemCount = mapping.updateMappings(startingWithGlobalItem: count) + count
            while count < newItemCount {
                globalItemToMappings[count] = mapping
                count += 1
            }
        }
        itemsCount = count
    }

    func mapping(for indexPath: IndexPath) -> _DataSourcesCollectionMapping? {
        return mappingForGlobalItem(indexPath.item)
    }

    func mappingForGlobalItem(_ item: Int) -> _SingleSectionMapping? {
        return globalItemToMappings[item]
    }

    // MARK: - Data Source

    func numberOfSections() -> Int {
        updateMappings()

        return 1
    }

    func numberOfItems(inSection section: Int) -> Int {
        updateMappings()

        return itemsCount
    }
}

extension _SingleSectionDataSourcesCollection {

    class _SingleSectionMapping: _DataSourcesCollectionMapping {

        private var globalItemStartIndex: Int = 0

        override func localItemForGlobalItem(_ globalItem: Int) -> Int {
            return globalItem - globalItemStartIndex
        }

        override func globalItemForLocalItem(_ localItem: Int) -> Int {
            return localItem + globalItemStartIndex
        }

        func updateMappings(startingWithGlobalItem globalItem: Int) -> Int {

            globalItemStartIndex = globalItem
            let itemCount = self.dataSource.ds_numberOfItems(inSection: 0)
            return itemCount
        }
    }
}
