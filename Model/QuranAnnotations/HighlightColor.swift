//
//  HighlightColor.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

public enum HighlightColor: Int, CaseIterable, Equatable, Hashable {
    case red = 0
    case green = 1
    case blue = 2
    case yellow = 3
    case purple = 4

    public var collectionName: String {
        switch self {
        case .red: return "red"
        case .green: return "green"
        case .blue: return "blue"
        case .yellow: return "yellow"
        case .purple: return "purple"
        }
    }

    public static var sortedColors: [Self] {
        [.yellow, .green, .blue, .red, .purple]
    }
}
