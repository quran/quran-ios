//
//  DataSourcesCollection.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 2/21/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

private class DataSourceWrapper : Hashable {
    let dataSource: DataSource
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    var hashValue: Int {
        return Unmanaged.passUnretained(dataSource).toOpaque().hashValue
    }
}

private func ==(lhs: DataSourceWrapper, rhs: DataSourceWrapper) -> Bool {
    return lhs.dataSource === rhs.dataSource
}

class DataSourcesCollection {
    
    unowned let parentDataSource: CompositeDataSource
    
    init(parentDataSource: CompositeDataSource) {
        self.parentDataSource = parentDataSource
    }
    
    var mappings: [Mapping] = []
    fileprivate var dataSourceToMappings: [DataSourceWrapper: Mapping] = [:]
    
    var dataSources: [DataSource] {
        return mappings.map { $0.dataSource }
    }
    
    fileprivate func createAndPrepareMappingForDataSource(_ dataSource: DataSource) -> Mapping {
        
        guard (dataSource as? CompositeDataSource)?.sectionType != .multi else {
            fatalError("Cannot add a multi-section composite data source as child data source.")
        }

        let wrapper = DataSourceWrapper(dataSource: dataSource)
        let existingMapping = dataSourceToMappings[wrapper]
        assert(existingMapping == nil, "Tried to add a data source more than once: \(dataSource)")
        
        let mapping = createMappingForDataSource(dataSource)
        dataSourceToMappings[wrapper] = mapping
        
        let collectionMapping = CompositeParentGeneralCollectionViewMapping(dataSource: dataSource, parentDataSource: parentDataSource)
        let delegate = DelegatedGeneralCollectionView(mapping: collectionMapping)
        // retain it
        mapping.reusableDelegate = delegate
        dataSource.ds_reusableViewDelegate = delegate
        
        return mapping
    }
    
    // MARK: API
    
    func addDataSource(_ dataSource: DataSource) {
        
        let mapping = createAndPrepareMappingForDataSource(dataSource)
        mappings.append(mapping)
        
        // update the mapping
        updateMappings()
    }
    
    func insertDataSource(_ dataSource: DataSource, atIndex index: Int) {
        
        assert(index >= 0 && index <= mappings.count, "Invalid index \(index) should be between [0..\(mappings.count)")
        
        let mapping = createAndPrepareMappingForDataSource(dataSource)
        mappings.insert(mapping, at: index)
        
        // update the mapping
        updateMappings()
    }
    
    func removeDataSource(_ dataSource: DataSource) {
        
        let wrapper = DataSourceWrapper(dataSource: dataSource)
        guard let exsitingMapping = dataSourceToMappings[wrapper] else {
            fatalError("Tried to remove a data source that doesn't exist: \(dataSource)")
        }
        guard let index = mappings.index(of: exsitingMapping) else {
            fatalError("Tried to remove a data source that doesn't exist: \(dataSource)")
        }
        
        dataSourceToMappings[wrapper] = nil
        mappings.remove(at: index)
        
        // update the mapping
        updateMappings()
    }

    func removeAllDataSources() {
        dataSourceToMappings.removeAll()
        mappings.removeAll()

        // update the mapping
        updateMappings()
    }
    
    func dataSourceAtIndex(_ index: Int) -> DataSource {
        return mappings[index].dataSource
    }
    
    func containsDataSource(_ dataSource: DataSource) -> Bool {
        return mappingForDataSource(dataSource) != nil
    }
    
    func indexOfDataSource(_ dataSource: DataSource) -> Int? {
        guard let mapping = mappingForDataSource(dataSource) else {
            return nil
        }
        return mappings.index(of: mapping)
    }
    
    func mappingForDataSource(_ dataSource: DataSource) -> Mapping? {
        let wrapper = DataSourceWrapper(dataSource: dataSource)
        let existingMapping = dataSourceToMappings[wrapper]
        return existingMapping
    }
    
    // MARK:- Subclassing
    
    func createMappingForDataSource(_ dataSource: DataSource) -> Mapping {
        fatalError("Should be implemented by subclasses")
    }
    
    func updateMappings() {
        fatalError("Should be implemented by subclasses")
    }
    
    func mappingForIndexPath(_ indexPath: IndexPath) -> Mapping {
        fatalError("Should be implemented by subclasses")
    }
    
    func numberOfSections() -> Int {
        fatalError("Should be implemented by subclasses")
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        fatalError("Should be implemented by subclasses")
    }
    
    // MARK:- API
    
    func globalIndexPathForLocalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.globalIndexPathForLocalIndexPath(indexPath)
    }
    
    func globalSectionForLocalSection(_ localSection: Int, dataSource: DataSource) -> Int {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to a composite data source")
        }
        
        return mapping.globalSectionForLocalSection(localSection)
    }
    
    func localIndexPathForGlobalIndexPath(_ indexPath: IndexPath, dataSource: DataSource) -> IndexPath {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.localIndexPathForGlobalIndexPath(indexPath)
    }
    
    func localSectionForGlobalSection(_ section: Int, dataSource: DataSource) -> Int {
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.localSectionForGlobalSection(section)
    }

    func collectionViewWrapperFromIndexPath(
        _ indexPath: IndexPath,
        collectionView: GeneralCollectionView)
        -> (dataSource: DataSource, localIndexPath: IndexPath, wrapperView: DelegatedGeneralCollectionView) {
            updateMappings()
            
            let mapping = mappingForIndexPath(indexPath)
            let localIndexPath = mapping.localIndexPathForGlobalIndexPath(indexPath)
            
            let wrapperMapping = GeneralCollectionViewWrapperMapping(mapping: mapping, view: collectionView)
            let wrapperView = DelegatedGeneralCollectionView(mapping: wrapperMapping)

            return (mapping.dataSource, localIndexPath, wrapperView)
    }
}

extension DataSourcesCollection {
    
    internal class Mapping : Equatable {
        
        /// retained
        var reusableDelegate: DelegatedGeneralCollectionView?
        
        let dataSource: DataSource
        
        init(dataSource: DataSource) {
            self.dataSource = dataSource
        }
        
        func localItemForGlobalItem(_ globalItem: Int) -> Int {
            return globalItem
        }
        
        func globalItemForLocalItem(_ localItem: Int) -> Int {
            return localItem
        }
        
        func localSectionForGlobalSection(_ globalSection: Int) -> Int {
            return globalSection
        }
        
        func globalSectionForLocalSection(_ localSection: Int) -> Int {
            return localSection
        }
        
        func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
            let localItem = localItemForGlobalItem((globalIndexPath as NSIndexPath).item)
            let localSection = localSectionForGlobalSection((globalIndexPath as NSIndexPath).section)
            return IndexPath(item: localItem, section: localSection)
        }

        func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
            let globalItem = globalItemForLocalItem((localIndexPath as NSIndexPath).item)
            let globalSection = globalSectionForLocalSection((localIndexPath as NSIndexPath).section)
            return IndexPath(item: globalItem, section: globalSection)
        }
    }
}

internal func ==(lhs: DataSourcesCollection.Mapping, rhs: DataSourcesCollection.Mapping) -> Bool {
    return lhs === rhs
}
