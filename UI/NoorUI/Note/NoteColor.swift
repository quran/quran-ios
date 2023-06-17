//
//  NoteColor.swift
//
//
//  Created by Afifi, Mohamed on 10/25/21.
//

import SwiftUI
import UIKit

public enum NoteColor {
    case red
    case green
    case blue
    case yellow
    case purple

    // MARK: Public

    public var uiColor: UIColor {
        switch self {
        case .red: return #colorLiteral(red: 0.9976003766, green: 0.6918323636, blue: 0.790571034, alpha: 1)
        case .green: return #colorLiteral(red: 0.7582061887, green: 0.9266348481, blue: 0.441752553, alpha: 1)
        case .blue: return #colorLiteral(red: 0.6776656508, green: 0.8418365121, blue: 0.994728744, alpha: 1)
        case .yellow: return #colorLiteral(red: 0.9911049008, green: 0.9235726595, blue: 0.3886876702, alpha: 1)
        case .purple: return #colorLiteral(red: 0.8482968211, green: 0.695538938, blue: 0.9965527654, alpha: 1)
        }
    }

    // MARK: Internal

    static var sortedColors: [NoteColor] {
        [.yellow, .green, .blue, .red, .purple]
    }

    var color: SwiftUI.Color {
        SwiftUI.Color(uiColor)
    }
}
