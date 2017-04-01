//
//  Cache.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

extension Hashable {
    fileprivate var hashNumber: NSNumber {
        return NSNumber(value: hashValue)
    }
}

private class ObjectWrapper {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }
}

open class Cache<KeyType: Hashable, ObjectType> {

    private let cache: NSCache<NSNumber, ObjectWrapper> = NSCache()

    public init(lowMemoryAware: Bool = true) {
        guard lowMemoryAware else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLowMemory),
            name: .UIApplicationDidReceiveMemoryWarning,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func onLowMemory() {
        removeAllObjects()
    }

    open var name: String {
        get { return cache.name }
        set { cache.name = newValue }
    }

    weak open var delegate: NSCacheDelegate? {
        get { return cache.delegate }
        set { cache.delegate = newValue }
    }

    open func object(forKey key: KeyType) -> ObjectType? {
        return cache.object(forKey: key.hashNumber)?.value as? ObjectType
    }

    open func setObject(_ obj: ObjectType, forKey key: KeyType) { // 0 cost
        return cache.setObject(ObjectWrapper(obj), forKey: key.hashNumber)
    }

    open func setObject(_ obj: ObjectType, forKey key: KeyType, cost: Int) {
        return cache.setObject(ObjectWrapper(obj), forKey: key.hashNumber, cost: cost)
    }

    open func removeObject(forKey key: KeyType) {
        return cache.removeObject(forKey: key.hashNumber)
    }

    open func removeAllObjects() {
        return cache.removeAllObjects()
    }

    open var totalCostLimit: Int {
        get { return cache.totalCostLimit }
        set { cache.totalCostLimit = totalCostLimit }
    }

    open var countLimit: Int {
        get { return cache.countLimit }
        set { cache.countLimit = newValue }
    }

    open var evictsObjectsWithDiscardedContent: Bool {
        get { return cache.evictsObjectsWithDiscardedContent }
        set { cache.evictsObjectsWithDiscardedContent = newValue }
    }
}
