//
//  PreferenceKey.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

#if DEBUG
    private enum Statics {
        static var registeredKeys = Set<String>()
    }
#endif

public final class PreferenceKey<Type> {
    // MARK: Lifecycle

    public init(key: String, defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue

        #if DEBUG
            if Statics.registeredKeys.contains(key) {
                fatalError("PersistenceKey '\(key)' is registered multiple times")
            }
            Statics.registeredKeys.insert(key)
        #endif
    }

    init(_ key: String, _ defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue
    }

    // MARK: Public

    public let key: String
    public let defaultValue: Type
}
