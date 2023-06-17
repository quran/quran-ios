//
//  LazyAtomic.swift
//
//
//  Created by Mohamed Afifi on 2022-01-04.
//

import Foundation

@propertyWrapper
final class LazyAtomic<Value>: @unchecked Sendable {
    // MARK: Lifecycle

    init() {
    }

    // MARK: Internal

    var wrappedValue: () -> Value {
        get {
            {
                self.lock.lock()
                defer {
                    self.lock.unlock()
                }
                if let value = self.value {
                    return value
                }
                guard let initializer = self.initializer else {
                    fatalError("initializer must be set")
                }
                let initializedValue = initializer()
                self.value = initializedValue
                return initializedValue
            }
        }
        set {
            initializer = newValue
        }
    }

    // MARK: Private

    private var initializer: (() -> Value)?
    private var value: Value?
    private let lock = NSLock()
}
