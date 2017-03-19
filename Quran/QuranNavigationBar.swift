//
//  QuranNavigationBar.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

protocol QuranNavigationBarDelegate: class {
    var isBookmarked: Bool { get }
    var navigationItem: UINavigationItem { get }
    func onBookmarkButtonTapped()
    func onTranslationButtonTapped()
    func onSelectTranslationsButtonTapped()
}

class QuranNavigationBar {
    private let simplePersistence: SimplePersistence

    weak var delegate: QuranNavigationBarDelegate?

    private var isTranslationView: Bool {
        set { simplePersistence.setValue(newValue, forKey: .showQuranTranslationView) }
        get { return simplePersistence.valueForKey(.showQuranTranslationView) }
    }

    init(simplePersistence: SimplePersistence) {
        self.simplePersistence = simplePersistence
    }

    func updateRightBarItems(animated: Bool) {
        let isBookmarked = delegate?.isBookmarked ?? false
        let bookmarkImage = isBookmarked ? #imageLiteral(resourceName: "bookmark-filled") : #imageLiteral(resourceName: "bookmark-empty")
        let bookmark = UIBarButtonItem(image: bookmarkImage, style: .plain, target: self, action: #selector(onBookmarkTapped))
        if isBookmarked {
            bookmark.tintColor = .bookmark()
        }

        let translationImage = isTranslationView ? #imageLiteral(resourceName: "globe_filled-25") : #imageLiteral(resourceName: "globe-25")
        let translation = UIBarButtonItem(image: translationImage, style: .plain, target: self, action: #selector(onTranslationButtonTapped))

        var barItems = [translation, bookmark]
        if isTranslationView {
            let translationsSelection = UIBarButtonItem(image: #imageLiteral(resourceName: "Checklist_25"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(onSelectTranslationsTapped))
            barItems.insert(translationsSelection, at: 0)
        }

        delegate?.navigationItem.setRightBarButtonItems(barItems, animated: animated)
    }

    @objc private func onTranslationButtonTapped() {
        isTranslationView = !isTranslationView
        updateRightBarItems(animated: true)
        delegate?.onTranslationButtonTapped()
    }

    @objc private func onBookmarkTapped() {
        delegate?.onBookmarkButtonTapped()
        updateRightBarItems(animated: false)
    }

    @objc private func onSelectTranslationsTapped() {
        delegate?.onSelectTranslationsButtonTapped()
    }

}
