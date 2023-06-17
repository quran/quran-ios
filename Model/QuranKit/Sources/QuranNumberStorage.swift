//
//  QuranValueStorage.swift
//
//
//  Created by Mohamed Afifi on 2021-12-12.
//

import Foundation

struct QuranValueStorage<T: QuranValueGroup>: Hashable, Comparable, @unchecked Sendable {
    // MARK: Public

    public var next: T? {
        let values = quran[keyPath: keyPath]
        if self == values.last?.storage {
            return nil
        }
        return T(QuranValueStorage(quran: quran, value: value + 1, keyPath: keyPath))
    }

    public var previous: T? {
        let values = quran[keyPath: keyPath]
        if self == values.first?.storage {
            return nil
        }
        return T(QuranValueStorage(quran: quran, value: value - 1, keyPath: keyPath))
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.value < rhs.value
    }

    // MARK: Internal

    let quran: Quran
    let value: Int
    let keyPath: KeyPath<Quran, [T]>

    var description: String {
        "<\(T.self) value=\(value)>"
    }
}
