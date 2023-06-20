//
//  ContentImageContentView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-22.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import NoorUI
import QuranGeometry
import UIKit
import VLogging

@MainActor
public class ContentImageContentView: UIView {
    // MARK: Lifecycle

    public init(topView: UIView, bottomView: UIView, fullWindowView: Bool) {
        plainView = QuranImageView(topView: topView, bottomView: bottomView, fullWindowView: fullWindowView)
        super.init(frame: .zero)

        layoutController.quranImageView = plainView.mainImageView
        highlightingView.layoutController = layoutController

        addAutoLayoutSubview(highlightingView)
        addAutoLayoutSubview(plainView)

        plainView.vc.edges()

        highlightingView.vc.alignEdges(to: plainView.mainImageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var image: UIImage? {
        didSet {
            loadImage()
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        logger.info("Quran Image: userInterfaceStyle changed")
        loadImage()
    }

    public func configure(with element: PageMarkers) {
        let pageMarkersView = PageMarkersView()
        pageMarkers = pageMarkersView
        pageMarkersView.pageMarkers = element
    }

    // MARK: Internal

    let plainView: QuranImageView
    let highlightingView = QuranImageHighlightingView()

    // MARK: Private

    private let layoutController = ContentImageLayoutController()

    // MARK: - PageMarkers

    private var pageMarkers: PageMarkersView? {
        didSet {
            oldValue?.removeFromSuperview()

            pageMarkers?.layoutController = layoutController
            if let pageMarkers {
                addAutoLayoutSubview(pageMarkers)
                pageMarkers.vc.alignEdges(to: plainView.mainImageView)
            }
        }
    }

    private func loadImage() {
        logger.info("Quran Image: load image")
        setImage(image)
        guard traitCollection.userInterfaceStyle == .dark else {
            return
        }
        let oldImage = image
        // TODO: Use async/await
        DispatchQueue.global(qos: .userInteractive).async {
            let inverted = oldImage?.inverted()
            DispatchQueue.main.async {
                if self.image == oldImage && self.traitCollection.userInterfaceStyle == .dark {
                    self.setImage(inverted)
                }
            }
        }
    }

    private func setImage(_ image: UIImage?) {
        plainView.mainImageView.image = image
        plainView.setNeedsLayout()
        highlightingView.setNeedsLayout()
        pageMarkers?.setNeedsLayout()
    }
}
