//
//  HighlightColor.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

public enum HighlightColor: String, CaseIterable, Equatable, Hashable {
    case red
    case green
    case blue
    case yellow
    case purple

    public init?(collectionName: String) {
        self.init(rawValue: collectionName)
    }

    public var collectionName: String {
        rawValue
    }
}
