//
//  ReadingInfo.swift
//
//
//  Created by Mohamed Afifi on 2023-02-13.
//

import Localization
import QuranKit

struct ReadingInfo<Value: Hashable>: Hashable, Identifiable {
    // MARK: Lifecycle

    init(value: Value, title: String, description: String, properties: [Reading.Property]) {
        self.value = value
        self.title = title
        self.description = description
        self.properties = properties
    }

    // MARK: Internal

    let value: Value
    let title: String
    let description: String
    let properties: [Reading.Property]

    var id: Value { value }
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
                ]
            )
        }
    }
}
