//
//  ReadingInfo.swift
//
//
//  Created by Mohamed Afifi on 2023-02-13.
//

import Foundation
import Localization

public struct ReadingInfo<Value: Hashable>: Hashable, Identifiable {
    struct Property: Hashable {
        enum PropertType {
            case supports
            case lacks
        }

        let type: PropertType
        let property: String

        init(property: String) {
            if property.hasPrefix("!") {
                type = .lacks
                self.property = property.replacingOccurrences(of: "!", with: "")
            } else {
                type = .supports
                self.property = property
            }
        }
    }

    public let value: Value
    public let title: String
    public let description: String
    let properties: [Property]

    public var id: Value { value }

    public init(value: Value, title: String, description: String, properties: String) {
        self.value = value
        self.title = title
        self.description = description
        self.properties = properties.components(separatedBy: "\n").map(Property.init)
    }
}

// Test data
enum ReadingInfoTestData {
    enum Reading: CaseIterable {
        case a, b, c, d, e
    }

    static var readings: [ReadingInfo<Reading>] {
        Reading.allCases.map {
            ReadingInfo<Reading>(
                value: $0,
                title: l("reading.hafs-1405.title"),
                description: l("reading.hafs-1405.description"),
                properties: l("reading.hafs-1405.properties")
            )
        }
    }
}
