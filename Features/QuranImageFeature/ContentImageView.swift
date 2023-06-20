//
//  ContentImageView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/30/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import ImageService
import Localization
import NoorUI
import QuranAnnotations
import QuranGeometry
import QuranKit
import QuranTextKit
import UIKit
import VLogging

class ContentImageView: UIView {
    // MARK: Lifecycle

    init() {
        imageView = ContentImageContentView(topView: topView, bottomView: bottomView, fullWindowView: true)
        super.init(frame: .zero)

        addAutoLayoutSubview(imageView)
        imageView.vc.edges()

        setupTopView(topView)
        setupBottomView(bottomView)

        for label in [juzLabel, suraLabel, pageLabel] {
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .label
        }
        pageLabel.textAlignment = .center
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - PageView

    var quranUITraits = QuranUITraits() {
        didSet {
            logger.info("Quran Image: quranUITraits changed")
            let newHighlights = quranUITraits.versesHighlights
            let oldHighlights = oldValue.versesHighlights

            highlightingView.highlightedWord = quranUITraits.highlightedWord
            highlightingView.highlights = newHighlights

            for type in QuranHighlightType.scrollingTypes {
                if oldHighlights[type]?.map(\.verse) != newHighlights[type]?.map(\..verse) {
                    scrollToVerseIfNeeded()
                    break
                }
            }
        }
    }

    var page: Page? {
        didSet {
            imageView.image = nil
            guard let page else {
                return
            }

            logger.info("Quran Image: set page \(page)")

            // configure the cell
            pageLabel.text = page.localizedNumber
        }
    }

    func word(at point: CGPoint) -> Word? {
        let localPoint = highlightingView.convert(point, from: self)
        return highlightingView.word(at: localPoint, view: self)
    }

    func verse(at point: CGPoint) -> AyahNumber? {
        word(at: point)?.verse
    }

    func configure(with element: ImagePage) {
        suraLabel.attributedText = element.startAyah.page.suraNames()
        juzLabel.text = element.startAyah.page.localizedQuarterName
        imageView.image = element.image
        highlightingView.wordFrames = element.wordFrames
        scrollToVerseIfNeeded()
    }

    func configure(with element: PageMarkers) {
        imageView.configure(with: element)
    }

    // MARK: Private

    private let imageView: ContentImageContentView

    private let topView = UIView()
    private let bottomView = UIView()

    private let juzLabel = UILabel()
    private let suraLabel = UILabel()
    private let pageLabel = UILabel()

    private var highlightingView: QuranImageHighlightingView {
        imageView.highlightingView
    }

    private var scrollView: UIScrollView {
        imageView.plainView.scrollView
    }

    private func setupTopView(_ topView: UIView) {
        topView.addAutoLayoutSubview(juzLabel)
        juzLabel.vc.verticalEdges()
        juzLabel.vc.leading()

        topView.addAutoLayoutSubview(suraLabel)
        suraLabel.vc.verticalEdges()
        suraLabel.vc.trailing()

        suraLabel.leadingAnchor.constraint(greaterThanOrEqualTo: juzLabel.trailingAnchor, constant: 40).isActive = true
        juzLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        juzLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
    }

    private func setupBottomView(_ bottomView: UIView) {
        bottomView.addAutoLayoutSubview(pageLabel)
        pageLabel.vc.edges()
    }

    private func scrollToVerseIfNeededSynchronously() {
        guard let ayah = highlightingView.highlights.firstScrollingToVerse() else {
            return
        }

        guard let ayahInfo = highlightingView.wordFrames?.wordFramesForVerse(ayah) else {
            return
        }
        let rectangles = ayahInfo.map(\.rect)

        guard !rectangles.isEmpty else {
            return
        }

        logger.info("Quran Image: scrollToVerseIfNeeded")

        layoutIfNeeded()

        let union = highlightingView.scaledUnion(of: rectangles)
        let origin = scrollView.convert(union.origin, from: highlightingView)
        let proposedContentOffset = origin.y - (readableContentInsets.top + 60)
        let contentOffset = max(0, min(proposedContentOffset, scrollView.contentSize.height - scrollView.bounds.height))
        scrollView.setContentOffset(CGPoint(x: 0, y: contentOffset), animated: true)
    }

    private func scrollToVerseIfNeeded() {
        // Execute in the next runloop to allow the collection view to load.
        DispatchQueue.main.async {
            self.scrollToVerseIfNeededSynchronously()
        }
    }
}
