//
//  SingleSectionDataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class SingleSectionDataSourcesCollection: DataSourcesCollection {

    fileprivate var itemsCount: Int = 0

    fileprivate var globalItemToMappings: [Int: SingleSectionMapping] = [:]

    override func createMappingForDataSource(_ dataSource: DataSource) -> Mapping {
        return SingleSectionMapping(dataSource: dataSource)
    }

    override func updateMappings() {

        // reset
        var count = 0
        globalItemToMappings.removeAll()

        for mapping in mappings {
            guard let mapping = mapping as? SingleSectionMapping else {
                fatalError("Mappings for \(type(of: self)) should be of type \(SingleSectionMapping.self)")
            }

            let newItemCount = mapping.updateMappings(startingWithGlobalItem: count) + count
            while (count < newItemCount) {
                globalItemToMappings[count] = mapping
                count += 1
            }
        }
        itemsCount = count
    }

    override func mappingForIndexPath(_ indexPath: IndexPath) -> Mapping {
        return mappingForGlobalItem((indexPath as NSIndexPath).item)
    }

    func mappingForGlobalItem(_ item: Int) -> SingleSectionMapping {
        guard let mapping = globalItemToMappings[item] else {
            fatalError("Couldn't find mapping for item: \(item)")
        }
        return mapping
    }

    // MARK:- Data Source

    override func numberOfSections() -> Int {
        updateMappings()

        return 1
    }

    override func numberOfItems(inSection section: Int) -> Int {
        updateMappings()

        return itemsCount
    }
}

extension SingleSectionDataSourcesCollection {

    internal class SingleSectionMapping : Mapping {

        fileprivate var globalItemStartIndex: Int = 0

        override func localItemForGlobalItem(_ globalItem: Int) -> Int {
            return globalItem - globalItemStartIndex
        }

        override func globalItemForLocalItem(_ localItem: Int) -> Int {
            return localItem + globalItemStartIndex
        }

        func updateMappings(startingWithGlobalItem globalItem:Int) -> Int {

            globalItemStartIndex = globalItem
            let itemCount = self.dataSource.ds_numberOfItems(inSection: 0)
            return itemCount
        }
    }
}
