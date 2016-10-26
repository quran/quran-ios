//
//  MultiSectionDataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class MultiSectionDataSourcesCollection: DataSourcesCollection {
    fileprivate var sectionsCount: Int = 0

    fileprivate var globalSectionToMappings: [Int: MutliSectionMapping] = [:]

    override func createMappingForDataSource(_ dataSource: DataSource) -> Mapping {
        return MutliSectionMapping(dataSource: dataSource)
    }

    override func updateMappings() {

        // reset
        var count = 0
        globalSectionToMappings.removeAll()

        for mapping in mappings {
            guard let mapping = mapping as? MutliSectionMapping else {
                fatalError("Mappings for \(type(of: self)) should be of type \(MutliSectionMapping.self)")
            }

            let newSectionCount = mapping.updateMappings(startingWithGlobalSection: count) + count
            while (count < newSectionCount) {
                globalSectionToMappings[count] = mapping
                count += 1
            }
        }
        sectionsCount = count
    }

    override func mappingForIndexPath(_ indexPath: IndexPath) -> Mapping {
        return mappingForGlobalSection((indexPath as NSIndexPath).section)
    }

    func mappingForGlobalSection(_ section: Int) -> MutliSectionMapping {
        guard let mapping = globalSectionToMappings[section] else {
            fatalError("Couldn't find mapping for section: \(section)")
        }
        return mapping
    }

    // MARK:- Data Source

    override func numberOfSections() -> Int {
        updateMappings()

        return sectionsCount
    }

    override func numberOfItems(inSection section: Int) -> Int {
        updateMappings()

        let mapping = mappingForGlobalSection(section)
        return mapping.dataSource.ds_numberOfItems(inSection: 0)
    }
}

extension MultiSectionDataSourcesCollection {

    internal class MutliSectionMapping : Mapping {

        fileprivate var globalSectionStartIndex: Int = 0

        override func localSectionForGlobalSection(_ globalSection: Int) -> Int {
            return globalSection - globalSectionStartIndex
        }

        override func globalSectionForLocalSection(_ localSection: Int) -> Int {
            return localSection + globalSectionStartIndex
        }

        func updateMappings(startingWithGlobalSection globalSection:Int) -> Int {

            globalSectionStartIndex = globalSection
            let sectionCount = self.dataSource.ds_numberOfSections()
            return sectionCount
        }
    }
}
