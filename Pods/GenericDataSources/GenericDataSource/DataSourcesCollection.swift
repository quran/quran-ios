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
        return unsafeAddressOf(dataSource).hashValue
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
    private var dataSourceToMappings: [DataSourceWrapper: Mapping] = [:]
    
    var dataSources: [DataSource] {
        return mappings.map { $0.dataSource }
    }
    
    private func createAndPrepareMappingForDataSource(dataSource: DataSource) -> Mapping {
        
        guard (dataSource as? CompositeDataSource)?.type != .MultiSection else {
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
    
    func addDataSource(dataSource: DataSource) {
        
        let mapping = createAndPrepareMappingForDataSource(dataSource)
        mappings.append(mapping)
        
        // update the mapping
        updateMappings()
    }
    
    func insertDataSource(dataSource: DataSource, atIndex index: Int) {
        
        assert(index >= 0 && index <= mappings.count, "Invalid index \(index) should be between [0..\(mappings.count)")
        
        let mapping = createAndPrepareMappingForDataSource(dataSource)
        mappings.insert(mapping, atIndex: index)
        
        // update the mapping
        updateMappings()
    }
    
    func removeDataSource(dataSource: DataSource) {
        
        let wrapper = DataSourceWrapper(dataSource: dataSource)
        guard let exsitingMapping = dataSourceToMappings[wrapper] else {
            fatalError("Tried to remove a data source that doesn't exist: \(dataSource)")
        }
        guard let index = mappings.indexOf(exsitingMapping) else {
            fatalError("Tried to remove a data source that doesn't exist: \(dataSource)")
        }
        
        dataSourceToMappings[wrapper] = nil
        mappings.removeAtIndex(index)
        
        // update the mapping
        updateMappings()
    }
    
    func dataSourceAtIndex(index: Int) -> DataSource {
        return mappings[index].dataSource
    }
    
    func containsDataSource(dataSource: DataSource) -> Bool {
        return mappingForDataSource(dataSource) != nil
    }
    
    func indexOfDataSource(dataSource: DataSource) -> Int? {
        guard let mapping = mappingForDataSource(dataSource) else {
            return nil
        }
        return mappings.indexOf(mapping)
    }
    
    func mappingForDataSource(dataSource: DataSource) -> Mapping? {
        let wrapper = DataSourceWrapper(dataSource: dataSource)
        let existingMapping = dataSourceToMappings[wrapper]
        return existingMapping
    }
    
    // MARK:- Subclassing
    
    func createMappingForDataSource(dataSource: DataSource) -> Mapping {
        fatalError("Should be implemented by subclasses")
    }
    
    func updateMappings() {
        fatalError("Should be implemented by subclasses")
    }
    
    func mappingForIndexPath(indexPath: NSIndexPath) -> Mapping {
        fatalError("Should be implemented by subclasses")
    }
    
    func numberOfSections() -> Int {
        fatalError("Should be implemented by subclasses")
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        fatalError("Should be implemented by subclasses")
    }
    
    // MARK:- API
    
    func globalIndexPathForLocalIndexPath(indexPath: NSIndexPath, dataSource: DataSource) -> NSIndexPath {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.globalIndexPathForLocalIndexPath(indexPath)
    }
    
    func globalSectionForLocalSection(localSection: Int, dataSource: DataSource) -> Int {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to a composite data source")
        }
        
        return mapping.globalSectionForLocalSection(localSection)
    }
    
    func localIndexPathForGlobalIndexPath(indexPath: NSIndexPath, dataSource: DataSource) -> NSIndexPath {
        
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.localIndexPathForGlobalIndexPath(indexPath)
    }
    
    func localSectionForGlobalSection(section: Int, dataSource: DataSource) -> Int {
        guard let mapping = mappingForDataSource(dataSource) else {
            fatalError("dataSource is not a child to composite data source")
        }
        
        return mapping.localSectionForGlobalSection(section)
    }

    func collectionViewWrapperFromIndexPath(
        indexPath: NSIndexPath,
        collectionView: GeneralCollectionView)
        -> (dataSource: DataSource, localIndexPath: NSIndexPath, wrapperView: DelegatedGeneralCollectionView) {
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
        
        func localItemForGlobalItem(globalItem: Int) -> Int {
            return globalItem
        }
        
        func globalItemForLocalItem(localItem: Int) -> Int {
            return localItem
        }
        
        func localSectionForGlobalSection(globalSection: Int) -> Int {
            return globalSection
        }
        
        func globalSectionForLocalSection(localSection: Int) -> Int {
            return localSection
        }
        
        func localIndexPathForGlobalIndexPath(globalIndexPath: NSIndexPath) -> NSIndexPath {
            let localItem = localItemForGlobalItem(globalIndexPath.item)
            let localSection = localSectionForGlobalSection(globalIndexPath.section)
            return NSIndexPath(forItem: localItem, inSection: localSection)
        }

        func globalIndexPathForLocalIndexPath(localIndexPath: NSIndexPath) -> NSIndexPath {
            let globalItem = globalItemForLocalItem(localIndexPath.item)
            let globalSection = globalSectionForLocalSection(localIndexPath.section)
            return NSIndexPath(forItem: globalItem, inSection: globalSection)
        }
    }
}

internal func ==(lhs: DataSourcesCollection.Mapping, rhs: DataSourcesCollection.Mapping) -> Bool {
    return lhs === rhs
}