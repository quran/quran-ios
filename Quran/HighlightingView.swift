//
//  HighlightingView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/24/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import MenuItemKit

enum HighlightType: Int {
    case reading
    case share
    case bookmark

    fileprivate var color: UIColor {
        switch self {
        case .reading   : return UIColor.appIdentity().withAlphaComponent(0.25)
        case .share     : return UIColor.selection().withAlphaComponent(0.25)
        case .bookmark  : return UIColor.bookmark().withAlphaComponent(0.25)
        }
    }

    fileprivate static let sortedTypes: [HighlightType] = [.share, .reading, .bookmark]
}

protocol HighlightingViewDelegate: class {
    func highlightingView(_ highlightingView: HighlightingView, didShareAyahText ayahText: String)
}

// This class is expected to be implemented using CoreAnimation with CAShapeLayers.
// It's also expected to reuse layers instead of dropping & creating new ones.
class HighlightingView: UIView {

    weak var delegate: HighlightingViewDelegate?

    private var resignGestures: [UIGestureRecognizer] = []

    var bookmarkPersistence: BookmarksPersistence!

    var highlights: [HighlightType: Set<AyahNumber>] = [:] {
        didSet { updateRectangleBounds() }
    }

    var ayahInfoData: [AyahNumber: [AyahInfo]]? {
        didSet { updateRectangleBounds() }
    }

    var page: Int = 0

    private var imageScale: CGFloat = 0.0
    private var xOffset: CGFloat = 0.0
    private var yOffset: CGFloat = 0.0

    var highlightingRectangles: [HighlightType: [CGRect]] = [:]

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard highlights.count > 0 else { return }

        let context = UIGraphicsGetCurrentContext()
        for (highlightType, rectangles) in highlightingRectangles {
            context?.setFillColor(highlightType.color.cgColor)
            for rect in rectangles {
                context?.fill(rect)
            }
        }
    }

    func setScaleInfo(_ scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        self.imageScale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset

        updateRectangleBounds()
    }

    func reset() {
        highlights = [:]
        ayahInfoData = nil
        imageScale = 0.0
        xOffset = 0.0
        yOffset = 0.0
        page = 0
    }

    private func updateRectangleBounds() {

        highlightingRectangles.removeAll()
        var filteredHighlightAyats: [HighlightType: Set<AyahNumber>] = [:]

        for type in HighlightType.sortedTypes {
            let existingAyahts = filteredHighlightAyats.reduce(Set<AyahNumber>()) { $0.union($1.value) }
            var ayats = highlights[type] ?? Set<AyahNumber>()
            ayats = ayats.subtracting(existingAyahts)
            filteredHighlightAyats[type] = ayats
        }

        for (type, ayat) in filteredHighlightAyats {
            var rectangles: [CGRect] = []
            for ayah in ayat {
                guard let ayahInfo = ayahInfoData?[ayah] else { continue }
                for piece in ayahInfo {
                    let rectangle = piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                    rectangles.append(rectangle)
                }
            }
            highlightingRectangles[type] = rectangles
        }

        setNeedsDisplay()
    }

    // MARK: - Menu Controller (Clipboard) -

    /**
     Highlight a verse that contains a given touch location.
     The verse will be highlighted and a menu controller will be displayed with options like Copy and Share the verse.
     - Parameter location: The touch location where we check the verse that match the location to highlight
     - Returns: true if a verse is found and match the location, false otherwise.
     */
    func highlightVerseAtLocation(_ location: CGPoint) -> Bool {

        guard let ayah = ayahNumber(at: location) else { return false }
        var set = Set<AyahNumber>()
        set.insert(ayah)
        highlights[.share] = set

        _ = becomeFirstResponder()
        return true
    }

    private func ayahNumber(at location: CGPoint) -> AyahNumber? {
        guard let ayahInfoData = ayahInfoData else { return nil }
        for (ayahNumber, ayahInfos) in ayahInfoData {
            for piece in ayahInfos {
                let rectangle = piece.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
                if rectangle.contains(location) {
                    return ayahNumber
                }
            }
        }

        return nil
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func viewPannedOrTapped() {
        _ = resignFirstResponder()
    }

    override func becomeFirstResponder() -> Bool {
        guard let selectedAyah = highlights[.share]?.first else { return false }
        guard let ayahInfo = ayahInfoData?[selectedAyah]?.first else { return false }

        // become first responder
        _ = super.becomeFirstResponder()

        // set up UIMenuController
        let rectangle = ayahInfo.rect.applyScale(imageScale, xOffset: xOffset, yOffset: yOffset)
        UIMenuController.shared.menuItems = [configuredBookmarkMenuItem(ayah: selectedAyah)]
        UIMenuController.shared.setTargetRect(rectangle, in: self)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        NotificationCenter.default.addObserver(self, selector: #selector(resignFirstResponder), name: .UIMenuControllerWillHideMenu, object: nil)

        // set up dismiss gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewPannedOrTapped))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewPannedOrTapped))
        resignGestures.append(contentsOf: [tap, pan])
        resignGestures.forEach { addGestureRecognizer($0) }

        return true
    }

    override func resignFirstResponder() -> Bool {
        // delete from the model
        highlights[.share] = nil

        // hide the menu controller
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillHideMenu, object: nil)
        UIMenuController.shared.setMenuVisible(false, animated: true)

        // remove gestures
        resignGestures.forEach { $0.isEnabled = false }
        resignGestures.forEach { $0.view?.removeGestureRecognizer($0) }
        resignGestures.removeAll()

        return super.resignFirstResponder()
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(HighlightingView.copy(_:)) || action == #selector(HighlightingView._share(_:)) {
            return true
        }
        return false
    }

    /// Did click on copy menu item
    override func copy(_ sender: Any?) {
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = currentSelectedAyahText()
    }

    /// Did click on share menu item
    func _share(_ sender: Any?) {
        let text = currentSelectedAyahText()
        if text.characters.count != 0 {
            delegate?.highlightingView(self, didShareAyahText: text)
        }
    }

    private func configuredBookmarkMenuItem(ayah: AyahNumber) -> UIMenuItem {
        let bookmarked = highlights[.bookmark]?.contains(ayah) ?? false
        if bookmarked {
            let image = UIImage(named: "bookmark-filled")?.tintedImage(withColor: .bookmark())
            return UIMenuItem(title: "Unbookmark", image: image) { [weak self] _ in
                guard let `self` = self else { return }
                Queue.bookmarks.async({ self.bookmarkPersistence.removeAyahBookmark(atPage: self.page, ayah: ayah) }) { _ in
                    var bookmarks = self.highlights[.bookmark] ?? Set()
                    bookmarks.remove(ayah)
                    self.highlights[.bookmark] = bookmarks
                }
            }
        } else {
            let image = UIImage(named: "bookmark-empty")?.tintedImage(withColor: .white)
            return UIMenuItem(title: "Bookmark", image: image) { [weak self] _ in
                guard let `self` = self else { return }
                Queue.bookmarks.async({ self.bookmarkPersistence.insertAyahBookmark(forPage: self.page, ayah: ayah) }) { _ in
                    var bookmarks = self.highlights[.bookmark] ?? Set()
                    bookmarks.insert(ayah)
                    self.highlights[.bookmark] = bookmarks
                }
            }
        }
    }

    /**
     Get the current highlighted ayah text.
     - Returns: String value representing the ayah
     */
    private func currentSelectedAyahText() -> String {
        return highlights[.share]?.first.map { ayahTextFromNumber($0) } ?? ""
    }

    /**
     Get ayah text given AyahNumber. Function connects AyahTextPersistenceStorage to get the text.
     - Parameter number: AyahNumber object represting the ayah number that you need its text.
     - Returns: the arabic text of ayah.
     */
    private func ayahTextFromNumber(_ number: AyahNumber) -> String {
        let storage = AyahTextPersistenceStorage()
        do {
            let text = try storage.getAyahTextForNumber(number)
            return text
        } catch {
            Crash.recordError(error)
        }
        return ""
    }
}
