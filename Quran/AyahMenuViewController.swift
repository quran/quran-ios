//
//  AyahMenuViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import MenuItemKit
import RIBs
import RxSwift
import UIKit

protocol AyahMenuCell: class {
    func highlightedVerse(forType type: QuranHighlightType) -> Set<AyahNumber>?
    func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: QuranHighlightType)
}

protocol AyahMenuPresentableListener: class {
    func willResignFirstResponder()
    func viewPanned()
    func viewTapped()
    func willHideMenu()
    func viewDidAppear()

    func onPlayTapped()
    func onRemoveBookmarkTapped()
    func onAddBookmarkTapped()
    func onCopyTapped()
    func onShareTapped()
    func onShareDismissed()
}

final class AyahMenuViewController: UIViewController, AyahMenuPresentable, AyahMenuViewControllable {

    weak var listener: AyahMenuPresentableListener?

    private let cell: AyahMenuCell & UIView
    private let pointInCell: CGPoint

    init(cell: AyahMenuCell & UIView, pointInCell: CGPoint) {
        self.cell = cell
        self.pointInCell = pointInCell
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        [tap, pan].forEach { view.addGestureRecognizer($0) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listener?.viewDidAppear()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        listener?.willResignFirstResponder()
        return super.resignFirstResponder()
    }

    func showMenuController(with data: AyahMenuData) {
        // highlight the ayah UI
        cell.setHighlightedVerses([data.ayah], forType: .share)

        // become first responder
        assert(becomeFirstResponder(), "UIMenuController will not work with a view that cannot become first responder")

        UIMenuController.shared.menuItems = [
            createPlayMenuItem(),
            configuredBookmarkMenuItem(isBookmarked: data.isBookmarked),
            createCopyMenuItem(),
            createShareMenuItem()
        ]
        UIMenuController.shared.setTargetRect(targetRect(for: pointInCell), in: cell)
        UIMenuController.shared.setMenuVisible(true, animated: true)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willHideMenu),
                                               name: UIMenuController.willHideMenuNotification,
                                               object: nil)
    }

    func cleanUp() {
        cell.setHighlightedVerses(nil, forType: .share)

        // hide the menu controller
        NotificationCenter.default.removeObserver(self, name: UIMenuController.willHideMenuNotification, object: nil)
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    @objc private func willHideMenu() {
        listener?.willHideMenu()
    }

    @objc private func viewPanned() {
        listener?.viewPanned()
    }

    @objc private func viewTapped() {
        listener?.viewTapped()
    }

    // MARK: - Copy & Share

    func shareText(_ lines: [String]) {
        let activityViewController = UIActivityViewController(activityItems: lines, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = cell
        activityViewController.popoverPresentationController?.sourceRect = targetRect(for: pointInCell)
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.listener?.onShareDismissed()
        }
        present(activityViewController, animated: true, completion: nil)
    }

    func copyText(_ lines: [String]) {
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = lines.joined(separator: "\n")
    }

    // MARK: - Highlighting

    func addAyahBookmark(ayah: AyahNumber) {
        var bookmarks = cell.highlightedVerse(forType: .bookmark) ?? Set()
        bookmarks.insert(ayah)
        cell.setHighlightedVerses(bookmarks, forType: .bookmark)
    }

    func removeAyahBookmarke(ayah: AyahNumber) {
        var bookmarks = cell.highlightedVerse(forType: .bookmark) ?? Set()
        bookmarks.remove(ayah)
        cell.setHighlightedVerses(bookmarks, forType: .bookmark)
    }

    // MARK: - Menu Items

    private func createPlayMenuItem() -> UIMenuItem {
        let image = #imageLiteral(resourceName: "ic_play").scaled(toHeight: 25)?.tintedImage(withColor: .white)
        return UIMenuItem(title: "Play", image: image) { [weak self] _ in
            self?.listener?.onPlayTapped()
        }
    }

    private func configuredBookmarkMenuItem(isBookmarked: Bool) -> UIMenuItem {
        if isBookmarked {
            let image = #imageLiteral(resourceName: "bookmark-filled").tintedImage(withColor: .bookmark())
            return UIMenuItem(title: "Unbookmark", image: image) { [weak self] _ in
                self?.listener?.onRemoveBookmarkTapped()
            }
        } else {
            let image = #imageLiteral(resourceName: "bookmark-empty").tintedImage(withColor: .white)
            return UIMenuItem(title: "Bookmark", image: image) { [weak self] _ in
                self?.listener?.onAddBookmarkTapped()
            }
        }
    }

    private func createCopyMenuItem() -> UIMenuItem {
        return UIMenuItem(title: l("verseCopy")) { [weak self] _ in
            self?.listener?.onCopyTapped()
        }
    }

    private func createShareMenuItem() -> UIMenuItem {
        return UIMenuItem(title: l("verseShare")) { [weak self] _ in
            self?.listener?.onShareTapped()
        }
    }

    private func targetRect(for point: CGPoint) -> CGRect {
        let size = CGSize(width: 20, height: 20)
        return CGRect(origin: CGPoint(x: point.x - size.width / 2,
                                      y: point.y - size.height / 2),
                      size: size)
    }
}
