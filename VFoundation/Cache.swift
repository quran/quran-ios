//
//  Cache.swift
//  Quran
//
//  Created by Mohamed Afifi on 11/1/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

private class ObjectWrapper {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }
}

private class KeyWrapper<KeyType: Hashable>: NSObject {
    let key: KeyType
    init(_ key: KeyType) {
        self.key = key
    }

    override var hash: Int {
        return key.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? KeyWrapper<KeyType> else {
            return false
        }
        return key == other.key
    }
}

open class Cache<KeyType: Hashable, ObjectType> {

    private let cache: NSCache<KeyWrapper<KeyType>, ObjectWrapper> = NSCache()

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
        return cache.object(forKey: KeyWrapper(key))?.value as? ObjectType
    }

    open func setObject(_ obj: ObjectType, forKey key: KeyType) { // 0 cost
        return cache.setObject(ObjectWrapper(obj), forKey: KeyWrapper(key))
    }

    open func setObject(_ obj: ObjectType, forKey key: KeyType, cost: Int) {
        return cache.setObject(ObjectWrapper(obj), forKey: KeyWrapper(key), cost: cost)
    }

    open func removeObject(forKey key: KeyType) {
        return cache.removeObject(forKey: KeyWrapper(key))
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
