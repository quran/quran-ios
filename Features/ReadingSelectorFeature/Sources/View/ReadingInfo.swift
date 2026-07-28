//
//  ReadingInfo.swift
//
//
//  Created by Mohamed Afifi on 2023-02-13.
//

import Localization
import QuranKit

struct ReadingBadge: Hashable {
    enum Style: Hashable {
        case informational
        case experimental
    }

    let title: String
    let style: Style
}

struct ReadingInfo<Value: Hashable>: Hashable, Identifiable {
    // MARK: Internal

    let value: Value
    let title: String
    let description: String
    let properties: [Reading.Property]
    let badge: ReadingBadge?

    var id: Value { value }
}

struct ReadingGroup<Value: Hashable>: Identifiable {
    let id: String
    let title: String
    let readings: [ReadingInfo<Value>]
}

// Test data
enum ReadingInfoTestData {
    enum Reading: CaseIterable {
        case a, b, c, d, e
    }

    // MARK: Internal

    static var readings: [ReadingInfo<Reading>] {
        Reading.allCases.map {
            ReadingInfo<Reading>(
                value: $0,
                title: l("reading.hafs-1405.title"),
                description: l("reading.hafs-1405.description"),
                properties: [
                    .init(type: .supports, property: "Property 1"),
                    .init(type: .supports, property: "Property 2"),
                    .init(type: .lacks, property: "Property 3"),
                ],
                badge: $0 == .e
                    ? ReadingBadge(title: "Experimental", style: .experimental)
                    : nil
            )
        }
    }

    static var groups: [ReadingGroup<Reading>] {
        [
            ReadingGroup(id: "a", title: "Uthmani", readings: Array(readings.prefix(3))),
            ReadingGroup(id: "b", title: "Tajweed", readings: [readings[3]]),
            ReadingGroup(id: "c", title: "Naskh", readings: [readings[4]]),
        ]
    }
}
