//
//  QuranGroup.swift
//
//
//  Created by Mohamed Afifi on 2021-12-11.
//

import Foundation

public protocol QuranGroup {
    var firstVerse: AyahNumber { get }
    var lastVerse: AyahNumber { get }
}

extension QuranGroup {
    public var verses: [AyahNumber] {
        firstVerse.array(to: lastVerse)
    }
}

protocol QuranValueGroup: QuranGroup, Navigatable {
    var storage: QuranValueStorage<Self> { get }
    init(_ storage: QuranValueStorage<Self>)
}

extension QuranValueGroup {
    public var description: String {
        storage.description
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.storage < rhs.storage
    }

    public var next: Self? {
        storage.next
    }

    public var previous: Self? {
        storage.previous
    }

    public var lastVerse: AyahNumber {
        if let next = next {
            return next.firstVerse.previous!
        }
        return storage.quran.lastVerse
    }
}
