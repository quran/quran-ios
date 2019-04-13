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
import Popover_OC
import UIKit
import ViewConstrainer

private struct GestureInfo {
    let cell: QuranBasePageCollectionViewCell
    let position: AyahWord.Position
}

protocol QuranViewDelegate: class {
    func quranViewHideBars()
    func onQuranViewTapped(_ quranView: QuranView)
    func onWordPointerTapped()
    func onViewLongTapped(cell: QuranBasePageCollectionViewCell, point: CGPoint)
}

class QuranView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: QuranViewDelegate?

    private weak var bottomBarConstraint: NSLayoutConstraint?

    private let dismissBarsTapGesture = UITapGestureRecognizer()
    private let wordByWordPersistence: WordByWordTranslationPersistence
    private let simplePersistence: SimplePersistence
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

    private lazy var popover: PopoverView = PopoverView(view: self)

    private var _pointerTop: NSLayoutConstraint?
    private var _pointerLeft: NSLayoutConstraint?
    private var _pointerParentSize: CGSize = .zero
    private func setPointerTop(_ value: CGFloat) {
        _pointerTop?.constant = value
        _pointerParentSize = bounds.size
    }
    private var minX: CGFloat {
        return Layout.windowDirectionalSafeAreaInsets.leading
    }
    private var maxX: CGFloat {
        return bounds.width - Layout.windowDirectionalSafeAreaInsets.trailing
    }

    lazy var pointer: UIView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "pointer-25").withRenderingMode(.alwaysTemplate)

        imageView.layer.shadowColor = Theme.Kind.labelWeak.color.cgColor
        imageView.layer.shadowOpacity = 0.6
        imageView.layer.shadowRadius = 3
        imageView.layer.shadowOffset = CGSize(width: 1, height: 1)

        let container = UIView()
        container.isHidden = true
        container.addAutoLayoutSubview(imageView)
        imageView.vc.center()

        self.addAutoLayoutSubview(container)
        self._pointerTop = container.vc
            .size(by: 44)
            .top().constraint
        self._pointerLeft = container.leftAnchor.constraint(equalTo: self.leftAnchor)
        self._pointerLeft?.isActive = true
        return container
    }()

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    init(wordByWordPersistence: WordByWordTranslationPersistence,
         simplePersistence: SimplePersistence) {
        self.wordByWordPersistence = wordByWordPersistence
        self.simplePersistence = simplePersistence
        super.init(frame: .zero)
        setUp()
    }

    private func setUp() {
        clipsToBounds = true
        dismissBarsTapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        dismissBarsTapGesture.delegate = self
        addGestureRecognizer(dismissBarsTapGesture)

        sendSubviewToBack(collectionView)
        bringSubviewToFront(pointer)

        // Long press gesture on verses to select
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))

        // pointer dragging
        let pointerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(onPointerPanned(_:)))
        pointer.addGestureRecognizer(pointerPanGesture)

        // pointer tapping
        pointer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pointerTapped)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !pointer.isHidden && _pointerParentSize != bounds.size {
            setPointerTop(pointer.frame.minY * bounds.height / _pointerParentSize.height)
            // using bounds.height because it has been rotated but pointer.frame.minX has not
            if pointer.frame.minX > bounds.height / 2 {
                _pointerLeft?.constant = maxX - pointer.bounds.width
            } else {
                _pointerLeft?.constant = minX
            }
        }
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

    // MARK: - MenuItems

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

    private func gestureInfo(at point: CGPoint) -> GestureInfo? {
        let collectionLocalPoint = collectionView.convert(point, from: self)
        guard let indexPath = collectionView.indexPathForItem(at: collectionLocalPoint) else {
            return nil
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuranBasePageCollectionViewCell else {
            return nil
        }
        let cellLocalPoint = cell.convert(point, from: self)
        guard let position = cell.ayahWordPosition(at: cellLocalPoint) else {
            return nil
        }
        return GestureInfo(cell: cell, position: position)
    }

    // MARK: - Word-by-word Pointer

    @objc
    func pointerTapped() {
        delegate?.onWordPointerTapped()
    }

    func showPointer() {
        pointer.isHidden = false

        setPointerTop(bounds.height)
        _pointerLeft?.constant = bounds.width / 2
        layoutIfNeeded()

        setPointerTop(bounds.height / 4)
        _pointerLeft?.constant = minX
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            self.layoutIfNeeded()
        }, completion: nil)
    }

    func hidePointer() {
        setPointerTop(bounds.height + 200)
        _pointerLeft?.constant = bounds.width / 2
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: {
            self.layoutIfNeeded()
        }, completion: { _ in
            if self._pointerTop?.constant == self.bounds.height + 200 {
                self.pointer.isHidden = true
            }
        })
    }

    private var pointerPositionOld: CGPoint = .zero
    @objc
    private func onPointerPanned(_ gesture: UIPanGestureRecognizer) {

        switch gesture.state {
        case .began:
            delegate?.quranViewHideBars()
            pointerPositionOld = CGPoint(x: pointer.frame.minX, y: pointer.frame.minY)
        case .changed:
            let translation = gesture.translation(in: self)
            setPointerTop(pointerPositionOld.y + translation.y)
            _pointerLeft?.constant = pointerPositionOld.x + translation.x
            layoutIfNeeded()
            showTip(at: CGPoint(x: pointer.frame.maxX - 15, y: pointer.frame.minY + 15))
        case .ended, .cancelled, .failed:
            hideTip()

            let velocity = gesture.velocity(in: self)

            let goLeft: Bool
            if abs(velocity.x) > 100 {
                goLeft = velocity.x < 0
            } else {
                goLeft = pointer.center.x < bounds.width / 2
            }

            let finalY = max(10, min(bounds.height - pointer.bounds.height, velocity.y * 0.3 + pointer.frame.minY))
            let finalX = goLeft ? minX : maxX - pointer.bounds.width

            let y = finalY - pointer.frame.minY
            let x = finalX - pointer.frame.minX
            let springVelocity = abs(velocity.x) / sqrt(x * x + y * y)

            setPointerTop(finalY)
            _pointerLeft?.constant = finalX
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: springVelocity, options: [], animations: {
                self.layoutIfNeeded()
            }, completion: nil)

        case .possible: break
        }
    }

    private var lastWord: AyahWord?

    private func showTip(at point: CGPoint) {
        guard let info = gestureInfo(at: point) else {
            hideTip()
            return
        }
        info.cell.highlight(position: info.position)

        let frame = convert(info.position.frame, from: info.cell)

        let isUpward = frame.minY < 63
        let point = CGPoint(x: frame.midX, y: isUpward ? frame.maxY + 10 : frame.minY - 10)

        var word: AyahWord?
        if lastWord?.position == info.position {
            word = lastWord
            show(word: lastWord, at: point, isUpward: isUpward)
        } else {
            let textType = simplePersistence.valueForKey(.wordTranslationType)
            suppress {
                word = try wordByWordPersistence.getWord(for: info.position, type: AyahWord.TextType(rawValue: textType) ?? .translation)
            }
        }
        show(word: word, at: point, isUpward: isUpward)
    }

    private func show(word: AyahWord?, at point: CGPoint, isUpward: Bool) {
        if let text = word?.text {
            let action = PopoverAction(title: text, handler: nil)
            popover.show(to: point, isUpward: isUpward, with: [action])
        } else {
            hideTip(updateLastWord: false)
        }
        if let word = word {
            lastWord = word
        }
    }

    private func hideTip(updateLastWord: Bool = true) {
        if updateLastWord {
            lastWord = nil
            for cell in collectionView.visibleCells {
                (cell as? QuranBasePageCollectionViewCell)?.highlight(position: nil)
            }
        }
        popover.hideNoAnimation()
    }
}
