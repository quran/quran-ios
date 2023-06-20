//
//  ContentImagePageMarkersView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-22.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import QuranGeometry
import QuranKit
import UIKit

class PageMarkersView: UIView {
    // MARK: Internal

    weak var layoutController: ContentImageLayoutController? {
        didSet {
            reloadViews()
        }
    }

    var pageMarkers: PageMarkers? {
        didSet {
            reloadViews()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateViewsFrames()
    }

    // MARK: Private

    private var suraHeaderViews: [(view: UIView, suraHeader: SuraHeaderLocation)] = []
    private var ayahNumberViews: [(view: UIView, ayahMarer: AyahNumberLocation)] = []

    private var imageScale: WordFrameScale {
        layoutController?.imageScale ?? .zero
    }

    private var ayahNumberLength: CGFloat {
        (layoutController?.imageWidth ?? 0) * AyahNumberView.lengthScale
    }

    private func reloadViews() {
        subviews.forEach { $0.removeFromSuperview() }
        if let pageMarkers {
            createViews(pageMarkers: pageMarkers)
        }
    }

    private func createViews(pageMarkers: PageMarkers) {
        let imageScale = imageScale
        for suraHeader in pageMarkers.suraHeaders {
            let view = UIImageView(image: #imageLiteral(resourceName: "sura_header"))
            view.tintColor = .pageMarkerTint
            view.frame = suraHeader.rect.scaled(by: imageScale)
            addSubview(view)
            suraHeaderViews.append((view, suraHeader))
        }

        for ayahNumber in pageMarkers.ayahNumbers {
            let view = AyahNumberView(ayah: ayahNumber.ayah)
            let rect = ayahNumber.rect(ofLength: ayahNumberLength)
            view.frame = rect.scaled(by: imageScale)
            addSubview(view)
            ayahNumberViews.append((view, ayahNumber))
        }
    }

    private func updateViewsFrames() {
        let imageScale = imageScale
        for (view, suraHeader) in suraHeaderViews {
            view.frame = suraHeader.rect.scaled(by: imageScale)
        }

        for (view, ayahNumber) in ayahNumberViews {
            let rect = ayahNumber.rect(ofLength: ayahNumberLength)
            view.frame = rect.scaled(by: imageScale)
        }
    }
}

private class AyahNumberView: UIView {
    // MARK: Lifecycle

    init(ayah: AyahNumber) {
        self.ayah = ayah
        super.init(frame: .zero)
        clipsToBounds = false

        decoration.tintColor = .pageMarkerTint
        addAutoLayoutSubview(decoration)
        decoration.vc.edges()

        addAutoLayoutSubview(label)
        label.vc.edges(inset: 0)

        label.textColor = .label
        label.textAlignment = .center
        label.text = NumberFormatter.arabicNumberFormatter.format(ayah.ayah)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let lengthScale: CGFloat = 0.06

    override var frame: CGRect {
        didSet {
            label.font = .boldSystemFont(ofSize: fontSize)
        }
    }

    // MARK: Private

    private static let fontScale: CGFloat = 0.0375
    private static let largeFontScale: CGFloat = 0.03

    private let decoration = UIImageView(image: #imageLiteral(resourceName: "ayah-end"))
    private let label = UILabel()
    private let ayah: AyahNumber

    private var fontSize: CGFloat {
        let fontScale = ayah.ayah > 99 ? Self.largeFontScale : Self.fontScale
        return fontScale * bounds.width / Self.lengthScale * 0.9
    }
}
