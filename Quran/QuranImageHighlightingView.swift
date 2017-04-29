//
//  QuranImageHighlightingView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
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

import UIKit

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class QuranImageHighlightingView: UIView {
    var highlights: [VerseHighlightType: Set<AyahNumber>] = [:] {
        didSet { updateRectangleBounds() }
    }

    var ayahInfoData: [AyahNumber: [AyahInfo]]? {
        didSet { updateRectangleBounds() }
    }

    var imageScale: CGRect.Scale = .zero {
        didSet { updateRectangleBounds() }
    }

    var highlightingRectangles: [VerseHighlightType: [CGRect]] = [:]

    func reset() {
        highlights = [:]
        ayahInfoData = nil
        imageScale = .zero
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !highlights.isEmpty else { return }

        let context = UIGraphicsGetCurrentContext()
        for (highlightType, rectangles) in highlightingRectangles {
            context?.setFillColor(highlightType.color.cgColor)
            for rect in rectangles {
                context?.fill(rect)
            }
        }
    }

    private func updateRectangleBounds() {

        highlightingRectangles.removeAll()
        var filteredHighlightAyats: [VerseHighlightType: Set<AyahNumber>] = [:]

        for type in VerseHighlightType.sortedTypes {
            let existingAyahts = filteredHighlightAyats.reduce(Set<AyahNumber>()) { $0.union($1.value) }
            var ayats = highlights[type] ?? Set<AyahNumber>()
            ayats.subtract(existingAyahts)
            filteredHighlightAyats[type] = ayats
        }

        for (type, ayat) in filteredHighlightAyats {
            var rectangles: [CGRect] = []
            for ayah in ayat {
                guard let ayahInfo = ayahInfoData?[ayah] else { continue }
                for piece in ayahInfo {
                    let rectangle = piece.rect.scaled(by: imageScale)
                    rectangles.append(rectangle)
                }
            }
            highlightingRectangles[type] = rectangles
        }

        setNeedsDisplay()
    }

    // MARK: - Location of ayah

    func ayahNumber(at location: CGPoint) -> AyahNumber? {
        guard let ayahInfoData = ayahInfoData else { return nil }
        for (ayahNumber, ayahInfos) in ayahInfoData {
            for piece in ayahInfos {
                let rectangle = piece.rect.scaled(by: imageScale)
                if rectangle.contains(location) {
                    return ayahNumber
                }
            }
        }
        return nil
    }
}
