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
import UIKit

private class ObjectWrapper {
    // MARK: Lifecycle

    init(_ value: Any) {
        self.value = value
    }

    // MARK: Internal

    let value: Any
}

private class KeyWrapper<KeyType: Hashable>: NSObject {
    // MARK: Lifecycle

    init(_ key: KeyType) {
        self.key = key
    }

    // MARK: Internal

    let key: KeyType

    override var hash: Int {
        key.hashValue
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? KeyWrapper<KeyType> else {
            return false
        }
        return key == other.key
    }
}

public final class Cache<KeyType: Hashable, ObjectType>: Sendable {
    // MARK: Lifecycle

    public init(lowMemoryAware: Bool = true) {
        guard lowMemoryAware else { return }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLowMemory),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Public

    public var name: String {
        get { cache.name }
        set { cache.name = newValue }
    }

    public weak var delegate: NSCacheDelegate? {
        get { cache.delegate }
        set { cache.delegate = newValue }
    }

    public var countLimit: Int {
        get { cache.countLimit }
        set { cache.countLimit = newValue }
    }

    public func object(forKey key: KeyType) -> ObjectType? {
        cache.object(forKey: KeyWrapper(key))?.value as? ObjectType
    }

    public func setObject(_ obj: ObjectType, forKey key: KeyType) { // 0 cost
        cache.setObject(ObjectWrapper(obj), forKey: KeyWrapper(key))
    }

    public func removeObject(forKey key: KeyType) {
        cache.removeObject(forKey: KeyWrapper(key))
    }

    public func removeAllObjects() {
        cache.removeAllObjects()
    }

    // MARK: Private

    private let cache: NSCache<KeyWrapper<KeyType>, ObjectWrapper> = NSCache()

    @objc
    private func onLowMemory() {
        removeAllObjects()
    }
}

extension NSCache: @unchecked Sendable {}
