//
//  PreferenceTransformer.swift
//
//
//  Created by Mohamed Afifi on 2022-09-10.
//

public struct PreferenceTransformer<Raw, T> {
    // MARK: Lifecycle

    public init(
        rawToValue: @escaping (Raw) -> T,
        valueToRaw: @escaping (T) -> Raw,
        isValidValue: @escaping (T) -> Bool = { _ in true }
    ) {
        self.rawToValue = rawToValue
        self.valueToRaw = valueToRaw
        self.isValidValue = isValidValue
    }

    // MARK: Public

    public let rawToValue: (Raw) -> T
    public let valueToRaw: (T) -> Raw
    /// Invalid values are ignored by `TransformedPreference`, preserving its stored value.
    public let isValidValue: (T) -> Bool
}

extension PreferenceTransformer where T: RawRepresentable, T.RawValue == Raw {
    public static func rawRepresentable(defaultValue: @escaping @autoclosure () -> T) -> Self {
        PreferenceTransformer(
            rawToValue: { T(rawValue: $0) ?? defaultValue() },
            valueToRaw: { $0.rawValue }
        )
    }
}

public func optionalTransfomer<Raw, T>(of transformer: PreferenceTransformer<Raw, T>) -> PreferenceTransformer<Raw?, T?> {
    PreferenceTransformer(
        rawToValue: { $0.map { transformer.rawToValue($0) } },
        valueToRaw: { $0.map { transformer.valueToRaw($0) } },
        isValidValue: { $0.map { transformer.isValidValue($0) } ?? true }
    )
}
