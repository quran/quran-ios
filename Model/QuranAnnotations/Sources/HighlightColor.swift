//
//  HighlightColor.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

public enum HighlightColor: Int, CaseIterable, Equatable, Hashable, Sendable {
    case red = 0
    case green = 1
    case blue = 2
    case yellow = 3
    case purple = 4

    public static var sortedColors: [Self] {
        [.yellow, .green, .blue, .red, .purple]
    }
}
