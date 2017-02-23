//
//  _MultiSectionDataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

class _MultiSectionDataSourcesCollection: NSObject, _DataSourcesCollection {
    private var sectionsCount: Int = 0

    private var globalSectionToMappings: [Int: _MutliSectionMapping] = [:]

    var mappings: _MappingCollection = _MappingCollection()

    unowned let parentDataSource: CompositeDataSource

    init(parentDataSource: CompositeDataSource) {
        self.parentDataSource = parentDataSource
    }

    func createMapping(for dataSource: DataSource) -> _DataSourcesCollectionMapping {
        return _MutliSectionMapping(dataSource: dataSource)
    }

    func updateMappings() {

        // reset
        var count = 0
        globalSectionToMappings.removeAll()

        for mapping in mappings.array {
            let mapping: _MutliSectionMapping = cast(mapping, message: "Mappings for \(type(of: self)) should be of type \(_MutliSectionMapping.self)")
            let newSectionCount = mapping.updateMappings(startingWithGlobalSection: count) + count
            while count < newSectionCount {
                globalSectionToMappings[count] = mapping
                count += 1
            }
        }
        sectionsCount = count
    }

    func mapping(for indexPath: IndexPath) -> _DataSourcesCollectionMapping? {
        return mappingForGlobalSection(indexPath.section)
    }

    func mappingForGlobalSection(_ section: Int) -> _MutliSectionMapping? {
        return globalSectionToMappings[section]
    }

    // MARK: - Data Source

    func numberOfSections() -> Int {
        updateMappings()

        return sectionsCount
    }

    func numberOfItems(inSection section: Int) -> Int {
        updateMappings()

        let mapping: _MutliSectionMapping = cast(mappingForGlobalSection(section),
                                                 message: "Cannot find mapping for section '\(section)' in a MultiSection data sources requesting numberOfItems.")
        return mapping.dataSource.ds_numberOfItems(inSection: 0)
    }
}

extension _MultiSectionDataSourcesCollection {

    class _MutliSectionMapping: _DataSourcesCollectionMapping {

        private var globalSectionStartIndex: Int = 0

        override func localSectionForGlobalSection(_ globalSection: Int) -> Int {
            return globalSection - globalSectionStartIndex
        }

        override func globalSectionForLocalSection(_ localSection: Int) -> Int {
            return localSection + globalSectionStartIndex
        }

        func updateMappings(startingWithGlobalSection globalSection: Int) -> Int {

            globalSectionStartIndex = globalSection
            let sectionCount = self.dataSource.ds_numberOfSections()
            return sectionCount
        }
    }
}
