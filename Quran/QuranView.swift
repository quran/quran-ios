//
//  QuranView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
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
import ViewConstrainer

protocol QuranViewDelegate: class {
    func onQuranViewTapped(_ quranView: QuranView)
    func onViewLongTapped(cell: QuranBasePageCollectionViewCell, point: CGPoint)
}

class QuranView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: QuranViewDelegate?

    private weak var bottomBarConstraint: NSLayoutConstraint?

    private let dismissBarsTapGesture = UITapGestureRecognizer()

    var audioView: UIView?

    lazy var collectionView: UICollectionView = {
        let layout = QuranPageFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = ThemedCollectionView(frame: self.bounds, collectionViewLayout: layout)
        collectionView.kind = .backgroundOLED
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 9.0, *) {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }
        self.addAutoLayoutSubview(collectionView)
        collectionView.vc
            .verticalEdges()
            .horizontalEdges(inset: -Layout.QuranCell.horizontalInset)

        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.ds_register(cellNib: QuranImagePageCollectionViewCell.self)
        collectionView.ds_register(cellNib: QuranTranslationCollectionPageCollectionViewCell.self)

        return collectionView
    }()

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    init() {
        super.init(frame: .zero)
        setUp()
    }

    private func setUp() {
        clipsToBounds = true
        dismissBarsTapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        dismissBarsTapGesture.delegate = self
        addGestureRecognizer(dismissBarsTapGesture)

        sendSubviewToBack(collectionView)

        // Long press gesture on verses to select
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))
    }

    func addWordPointerView(_ wordPointerView: UIView) {
        addAutoLayoutSubview(wordPointerView)
        wordPointerView.vc
            .top()
            .left()
    }

    func addAudioBannerView(_ audioBannerView: UIView) {
        self.audioView = audioBannerView
        addAutoLayoutSubview(audioBannerView)
        bottomBarConstraint = audioBannerView.vc
            .horizontalEdges()
            .bottom().constraint

        // Prevent long tap gesture on audio bottom bar
        audioBannerView.addGestureRecognizer(UILongPressGestureRecognizer(target: nil, action: nil))
    }

    func visibleIndexPath() -> IndexPath? {
        let offset = collectionView.contentOffset
        return collectionView.indexPathForItem(at: CGPoint(x: offset.x + bounds.width / 2, y: 0))
    }

    func setBarsHidden(_ hidden: Bool) {
        guard let audioView = audioView else {
            return
        }
        if let bottomBarConstraint = self.bottomBarConstraint {
            removeConstraint(bottomBarConstraint)
        }
        if hidden {
            bottomBarConstraint = self.vc.verticalLine(audioView, by: -1).constraint
        } else {
            bottomBarConstraint = audioView.vc.bottom().constraint
        }
    }

    @objc
    func onViewTapped(_ sender: UITapGestureRecognizer) {
        if let audioView = audioView, audioView.bounds.contains(sender.location(in: audioView)) {
            return
        }
        delegate?.onQuranViewTapped(self)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != dismissBarsTapGesture || !isFirstResponder // dismiss bars only if not first responder
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func onLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }

        let point = sender.location(in: self)
        let collectionLocalPoint = collectionView.convert(point, from: self)
        guard let indexPath = collectionView.indexPathForItem(at: collectionLocalPoint) else {
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuranBasePageCollectionViewCell else {
            return
        }
        let cellLocalPoint = cell.convert(point, from: self)

        delegate?.onViewLongTapped(cell: cell, point: cellLocalPoint)
    }

    // MARK: - word position

    func getWordPosition(at point: CGPoint, in view: UIView) -> AyahWord.Position? {
        let collectionLocalPoint = collectionView.convert(point, from: view)
        guard let indexPath = collectionView.indexPathForItem(at: collectionLocalPoint) else {
            return nil
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuranBasePageCollectionViewCell else {
            return nil
        }
        let cellLocalPoint = cell.convert(collectionLocalPoint, from: collectionView)
        guard let position = cell.ayahWordPosition(at: cellLocalPoint) else {
            return nil
        }
        return position
    }

    func highlightWordPosition(_ position: AyahWord.Position?) {
        let cells = collectionView.visibleCells.compactMap { $0 as? QuranBasePageCollectionViewCell }
        guard let position = position else {
            cells.forEach { $0.highlight(position: nil) }
            return
        }
        let page = Quran.pageForAyah(position.ayah)
        let cell = cells.first { $0.page?.pageNumber == page }
        cell?.highlight(position: position)
    }
}
