//
//  PreferenceTransformer.swift
//  
//
//  Created by Mohamed Afifi on 2022-09-10.
//

import Foundation

public struct PreferenceTransformer<Raw, T> {
    public let rawToValue: (Raw) -> T
    public let valueToRaw: (T) -> Raw

    public init(rawToValue: @escaping (Raw) -> T,
                valueToRaw: @escaping (T) -> Raw)
    {
        self.rawToValue = rawToValue
        self.valueToRaw = valueToRaw
    }
}

extension PreferenceTransformer where T: RawRepresentable, T.RawValue == Raw {
    public static func rawRepresentable(defaultValue: @escaping @autoclosure () -> T) -> Self {
        PreferenceTransformer(
            rawToValue: { T(rawValue: $0) ?? defaultValue() },
            valueToRaw: { $0.rawValue })
    }
}

public func optionalTransfomer<Raw, T>(of transformer: PreferenceTransformer<Raw, T>) -> PreferenceTransformer<Raw?, T?> {
    PreferenceTransformer(
        rawToValue: { $0.map { transformer.rawToValue($0) } },
        valueToRaw: { $0.map { transformer.valueToRaw($0) } })
}
