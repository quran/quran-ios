//
//  MultiSectionDataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class MultiSectionDataSourcesCollection: DataSourcesCollection {
    private var sectionsCount: Int = 0

    private var globalSectionToMappings: [Int: MutliSectionMapping] = [:]

    override func createMappingForDataSource(dataSource: DataSource) -> Mapping {
        return MutliSectionMapping(dataSource: dataSource)
    }

    override func updateMappings() {

        // reset
        var count = 0
        globalSectionToMappings.removeAll()

        for mapping in mappings {
            guard let mapping = mapping as? MutliSectionMapping else {
                fatalError("Mappings for \(self.dynamicType) should be of type \(MutliSectionMapping.self)")
            }

            let newSectionCount = mapping.updateMappings(startingWithGlobalSection: count) + count
            while (count < newSectionCount) {
                globalSectionToMappings[count] = mapping
                count += 1
            }
        }
        sectionsCount = count
    }

    override func mappingForIndexPath(indexPath: NSIndexPath) -> Mapping {
        return mappingForGlobalSection(indexPath.section)
    }

    func mappingForGlobalSection(section: Int) -> MutliSectionMapping {
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

        private var globalSectionStartIndex: Int = 0

        override func localSectionForGlobalSection(globalSection: Int) -> Int {
            return globalSection - globalSectionStartIndex
        }

        override func globalSectionForLocalSection(localSection: Int) -> Int {
            return localSection + globalSectionStartIndex
        }

        func updateMappings(startingWithGlobalSection globalSection:Int) -> Int {

            globalSectionStartIndex = globalSection
            let sectionCount = self.dataSource.ds_numberOfSections()
            return sectionCount
        }
    }
}