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

import QuranAnnotations
import QuranGeometry
import QuranKit
import UIKit

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class QuranImageHighlightingView: UIView {
    private typealias RectangleHighlights = [(type: QuranHighlightType, rects: [CGRect])]

    // MARK: Internal

    weak var layoutController: ContentImageLayoutController?

    var highlights: VerseHighlights = [:] {
        didSet { updateRectangleBounds() }
    }

    var wordFrames: WordFrameCollection? {
        didSet { updateRectangleBounds() }
    }

    var highlightedWord: Word? {
        didSet { updateRectangleBounds() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateViewsFrames()
    }

    // MARK: - Location of ayah

    func word(at location: CGPoint, view: UIView) -> Word? {
        wordFrames?.wordAtLocation(location, imageScale: imageScale)
    }

    func scaledUnion(of rectangles: [CGRect]) -> CGRect {
        var union = rectangles[0]
        rectangles.forEach { union = union.union($0) }
        union = union.scaled(by: imageScale)
        return union
    }

    // MARK: Private

    // MARK: - Children Views

    private var childrenViews: [(view: UIView, frame: CGRect)] = []

    private var imageScale: WordFrameScale {
        layoutController?.imageScale ?? .zero
    }

    private func updateRectangleBounds() {
        // remove duplicate highlights
        let versesByHighlights = highlights.versesByHighlights()

        var highlightingRectangles: RectangleHighlights = []
        for (ayah, type) in versesByHighlights {
            var rectangles: [CGRect] = []
            guard let ayahInfo = wordFrames?.wordFramesForVerse(ayah) else { continue }
            for piece in ayahInfo {
                rectangles.append(piece.rect)
            }
            highlightingRectangles.append((type, rectangles))
        }

        if let word = highlightedWord, let frame = wordFrames?.wordFrameForWord(word) {
            highlightingRectangles.append((.word, [frame.rect]))
        }

        createViews(highlightingRectangles: highlightingRectangles)
    }

    private func removeViews() {
        childrenViews.forEach { $0.view.removeFromSuperview() }
        childrenViews.removeAll()
    }

    private func createViews(highlightingRectangles: RectangleHighlights) {
        let imageScale = imageScale
        removeViews()
        for (highlightType, rectangles) in highlightingRectangles {
            for rect in rectangles {
                let rectView = UIView()
                rectView.backgroundColor = highlightType.color
                rectView.frame = rect.scaled(by: imageScale)
                addSubview(rectView)
                childrenViews.append((rectView, rect))
            }
        }
    }

    private func updateViewsFrames() {
        let imageScale = imageScale
        for (view, rect) in childrenViews {
            view.frame = rect.scaled(by: imageScale)
        }
    }
}
