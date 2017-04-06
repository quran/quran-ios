//
//  QuranView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import MenuItemKit

protocol QuranViewDelegate: class {
    func onQuranViewTapped(_ quranView: QuranView)
    func quranView(_ quranView: QuranView, didSelectTextToShare text: String)
    func onErrorOccurred(error: Error)
}

class QuranView: UIView, UIGestureRecognizerDelegate {

    weak var delegate: QuranViewDelegate?

    private weak var bottomBarConstraint: NSLayoutConstraint?

    private let dismissBarsTapGesture = UITapGestureRecognizer()
    private let bookmarksPersistence: BookmarksPersistence
    private let verseTextRetrieval: AnyInteractor<QuranShareData, String>

    private var shareData: QuranShareData? {
        didSet {
            // remove old gestures
            oldValue?.gestures.forEach { $0.view?.removeGestureRecognizer($0) }

            // add new gestures
            shareData?.gestures.forEach { addGestureRecognizer($0) }
            shareData?.gestures.forEach { $0.delegate = self }
        }
    }

    lazy var audioView: DefaultAudioBannerView = {
        let audioView = DefaultAudioBannerView()
        self.addAutoLayoutSubview(audioView)
        self.pinParentHorizontal(audioView)
        self.bottomBarConstraint = self.addParentBottomConstraint(audioView)
        return audioView
    }()

    lazy var collectionView: UICollectionView = {
        let layout = QuranPageFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        if #available(iOS 9.0, *) {
            collectionView.semanticContentAttribute = .forceRightToLeft
        }
        self.addAutoLayoutSubview(collectionView)
        self.pinParentAllDirections(collectionView, leadingValue: -5, trailingValue: -5)

        collectionView.backgroundColor = UIColor.readingBackground()
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.ds_register(cellNib: QuranImagePageCollectionViewCell.self)
        collectionView.ds_register(cellNib: QuranTranslationCollectionPageCollectionViewCell.self)

        return collectionView
    }()

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    init(bookmarksPersistence: BookmarksPersistence,
         verseTextRetrieval: AnyInteractor<QuranShareData, String>) {
        self.bookmarksPersistence = bookmarksPersistence
        self.verseTextRetrieval   = verseTextRetrieval
        super.init(frame: .zero)
        setUp()
    }

    private func setUp() {
        clipsToBounds = true
        dismissBarsTapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        dismissBarsTapGesture.delegate = self
        addGestureRecognizer(dismissBarsTapGesture)

        sendSubview(toBack: collectionView)
        bringSubview(toFront: audioView)

        // Long press gesture on verses to select
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:))))
    }

    func visibleIndexPath() -> IndexPath? {
        let offset = collectionView.contentOffset
        return collectionView.indexPathForItem(at: CGPoint(x: offset.x + bounds.width / 2, y: 0))
    }

    func setBarsHidden(_ hidden: Bool) {
        if let bottomBarConstraint = self.bottomBarConstraint {
            removeConstraint(bottomBarConstraint)
        }
        if hidden {
            bottomBarConstraint = addSiblingVerticalContiguous(top: self, bottom: audioView)
        } else {
            bottomBarConstraint = addParentBottomConstraint(audioView)
        }
    }

    func onViewTapped(_ sender: UITapGestureRecognizer) {
        guard !audioView.bounds.contains(sender.location(in: audioView)) else {
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

    @objc private func onLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        let collectionLocalPoint = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: collectionLocalPoint) else {
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? QuranBasePageCollectionViewCell else {
            return
        }
        guard let page = cell.page else {
            return
        }
        let cellLocalPoint = sender.location(in: cell)
        guard let ayah = cell.ayahNumber(at: cellLocalPoint) else {
            return
        }

        // set up dismiss gestures
        subviews.forEach { $0.isUserInteractionEnabled = false }

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPannedOrTapped))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewPannedOrTapped))
        let shareData = QuranShareData(gestures: [tap, pan], cell: cell, page: page, ayah: ayah)
        self.shareData = shareData

        // highlight the ayah UI
        cell.setHighlightedVerses(Set<AyahNumber>(ayah), forType: .share)

        // become first responder
        assert(becomeFirstResponder(), "UIMenuController will not work with a view that cannot become first responder")

        let localPoint = sender.location(in: self)
        let size = CGSize(width: 20, height: 20)
        let targetRect = CGRect(origin: CGPoint(x: localPoint.x - size.width / 2, y: localPoint.y - size.height / 2), size: size)
        UIMenuController.shared.menuItems = [configuredBookmarkMenuItem(shareData: shareData)]
        UIMenuController.shared.setTargetRect(targetRect, in: self)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(resignFirstResponder), name: .UIMenuControllerWillHideMenu, object: nil)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        // update the model
        shareData?.cell.setHighlightedVerses(nil, forType: .share)

        // hide the menu controller
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillHideMenu, object: nil)
        UIMenuController.shared.setMenuVisible(false, animated: true)

        // remove gestures
        subviews.forEach { $0.isUserInteractionEnabled = true }

        shareData = nil

        return super.resignFirstResponder()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(QuranView.copy(_:)) || action == #selector(QuranView._share(_:)) {
            return true
        }
        return false
    }

    @objc private func viewPannedOrTapped() {
        // resign first responder
        _ = resignFirstResponder()
    }

    /// Did click on copy menu item
    override func copy(_ sender: Any?) {
        retrieveSelectedAyahText { text in
            let pasteBoard = UIPasteboard.general
            pasteBoard.string = text
        }
    }

    /// Did click on share menu item
    func _share(_ sender: Any?) {
        retrieveSelectedAyahText { text in
            self.delegate?.quranView(self, didSelectTextToShare: text)
        }
    }

    private func configuredBookmarkMenuItem(shareData: QuranShareData) -> UIMenuItem {
        let isBookmarked = shareData.cell.highlightedVerse(forType: .bookmark)?.contains(shareData.ayah) ?? false
        if isBookmarked {
            let image = #imageLiteral(resourceName: "bookmark-filled").tintedImage(withColor: .bookmark())
            return UIMenuItem(title: "Unbookmark", image: image) { [weak self] _ in
                self?.removeAyahFromBookmarks(atPage: shareData.page.pageNumber, ayah: shareData.ayah, cell: shareData.cell)
            }
        } else {
            let image = #imageLiteral(resourceName: "bookmark-empty").tintedImage(withColor: .white)
            return UIMenuItem(title: "Bookmark", image: image) { [weak self] _ in
                self?.addAyahToBookmarks(atPage: shareData.page.pageNumber, ayah: shareData.ayah, cell: shareData.cell)
            }
        }
    }

    private func removeAyahFromBookmarks(atPage page: Int, ayah: AyahNumber, cell: QuranBasePageCollectionViewCell) {
        DispatchQueue.global()
            .promise { try self.bookmarksPersistence.removeAyahBookmark(atPage: page, ayah: ayah) }
            .then(on: .main) { _ -> Void in
                // remove bookmark from model
                var bookmarks = cell.highlightedVerse(forType: .bookmark) ?? Set()
                bookmarks.remove(ayah)
                cell.setHighlightedVerses(bookmarks, forType: .bookmark)
            }.cauterize(tag: "BookmarksPersistence.removeAyahBookmark")
    }

    private func addAyahToBookmarks(atPage page: Int, ayah: AyahNumber, cell: QuranBasePageCollectionViewCell) {
        DispatchQueue.global()
            .promise { try self.bookmarksPersistence.insertAyahBookmark(forPage: page, ayah: ayah) }
            .then(on: .main) { _ -> Void in
                // add a bookmark to the model
                var bookmarks = cell.highlightedVerse(forType: .bookmark) ?? Set()
                bookmarks.insert(ayah)
                cell.setHighlightedVerses(bookmarks, forType: .bookmark)
            }.cauterize(tag: "BookmarksPersistence.insertAyahBookmark")
    }

    /**
     Get the current highlighted ayah text.
     */
    private func retrieveSelectedAyahText(completion: @escaping (String) -> Void) {
        guard let shareData = shareData else {
            return
        }

        verseTextRetrieval
            .execute(shareData)
            .then(on: .main, execute: completion)
            .catch { (error) in
                self.delegate?.onErrorOccurred(error: error)
        }
    }
}
