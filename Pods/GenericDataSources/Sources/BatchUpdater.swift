//
//  BatchUpdater.swift
//  GenericDataSource
//
//  Created by Mohamed Afifi on 4/11/16.
//  Copyright © 2016 mohamede1945. All rights reserved.
//

import Foundation

protocol BatchUpdater: class {
    
    func actualPerformBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?)
}

extension UICollectionView : BatchUpdater {
    func actualPerformBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        performBatchUpdates(updates, completion: completion)
    }
}

extension UITableView : BatchUpdater {
    func actualPerformBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        beginUpdates()
        updates?()
        endUpdates()
        completion?(false)
    }
}

private class CompletionBlock {
    let block: (Bool) -> Void
    init(block: @escaping (Bool) -> Void) { self.block = block }
}

private struct AssociatedKeys {
    static var performingBatchUpdates = "performingBatchUpdates"
    static var completionBlocks = "completionBlocks"
}

extension GeneralCollectionView where Self : BatchUpdater {
    
    fileprivate var performingBatchUpdates: Bool {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.performingBatchUpdates) as? NSNumber
            return value?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.performingBatchUpdates, NSNumber(value: newValue as Bool), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var completionBlocks: [CompletionBlock] {
        get {
            let value = objc_getAssociatedObject(self, &AssociatedKeys.completionBlocks) as? [CompletionBlock]
            return value ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.completionBlocks, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func internal_performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)?) {
        guard !performingBatchUpdates else {
            if let completion = completion {
                var blocks = completionBlocks
                blocks.append(CompletionBlock(block: completion))
                completionBlocks = blocks
            }
            updates?()
            return
        }
        
        performingBatchUpdates = true
        actualPerformBatchUpdates(updates) { [weak self] completed in
            self?.performingBatchUpdates = false
            completion?(completed)
            for block in self?.completionBlocks ?? [] {
                block.block(completed)
            }
            self?.completionBlocks = []
        }
    }
}
