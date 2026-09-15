//
//  VerseOverlays+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/7/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import QuranAnnotations
import QuranKit
import SwiftUI
import UIKit

// TODO: Use SwiftUI.Color and remove UIColor usage.
extension VerseOverlays {
    public static let opacity = 0.3

    public static let wordHighlightColor = Color.appIdentity.opacity(opacity)

    static let playingColor = UIColor.appIdentity.withAlphaComponent(opacity)
    static let selectionColor = UIColor.systemBlue.withAlphaComponent(opacity)
    static let navigationColor = UIColor.systemGray.withAlphaComponent(opacity)

    // TODO: Use Color
    public func versesByHighlights() -> [AyahNumber: UIColor] {
        // Sort order: selection, playback, navigation, saved highlights
        var versesByHighlights: [AyahNumber: UIColor] = [:]

        for (verse, color) in colorHighlights {
            versesByHighlights[verse] = color.uiColor.withAlphaComponent(Self.opacity)
        }

        func add(verses: [AyahNumber], color: UIColor) {
            for verse in verses {
                versesByHighlights[verse] = color
            }
        }

        if let navigationTarget {
            versesByHighlights[navigationTarget] = Self.navigationColor
        }
        add(verses: playingVerses, color: Self.playingColor)
        add(verses: selectedVerses, color: Self.selectionColor)
        return versesByHighlights
    }
}
