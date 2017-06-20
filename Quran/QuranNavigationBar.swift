//
//  QuranNavigationBar.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
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

protocol QuranNavigationBarDelegate: class {
    var isBookmarked: Bool { get }
    var navigationItem: UINavigationItem { get }
    func onBookmarkButtonTapped()
    func onTranslationButtonTapped()
    func onSelectTranslationsButtonTapped()
    func onWordTranslationButtonTapped(isWordPointerActive: Bool)
}

class QuranNavigationBar {
    private let simplePersistence: SimplePersistence

    weak var delegate: QuranNavigationBarDelegate?

    var isTranslationView: Bool {
        set { simplePersistence.setValue(newValue, forKey: .showQuranTranslationView) }
        get { return simplePersistence.valueForKey(.showQuranTranslationView) }
    }
    var isWordPointerActive: Bool = false

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

        let barItems: [UIBarButtonItem]
        if isTranslationView {
            let translationsSelection = UIBarButtonItem(image: #imageLiteral(resourceName: "Checklist_25"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(onSelectTranslationsTapped))
            barItems = [bookmark, translation, translationsSelection]
        } else {
            let wordByWordImage = isWordPointerActive ? #imageLiteral(resourceName: "word-translation-filled-25") : #imageLiteral(resourceName: "word-translation-25")
            let wordByWord = UIBarButtonItem(image: wordByWordImage, style: .plain, target: self, action: #selector(onWordTranslationTapped))

            barItems = [bookmark, wordByWord, translation]
        }

        delegate?.navigationItem.setRightBarButtonItems(barItems, animated: animated)
    }

    @objc
    private func onTranslationButtonTapped() {
        isTranslationView = !isTranslationView
        updateRightBarItems(animated: false)
        delegate?.onTranslationButtonTapped()
    }

    @objc
    private func onBookmarkTapped() {
        delegate?.onBookmarkButtonTapped()
        updateRightBarItems(animated: false)
    }

    @objc
    private func onSelectTranslationsTapped() {
        delegate?.onSelectTranslationsButtonTapped()
    }

    @objc
    private func onWordTranslationTapped() {
        isWordPointerActive = !isWordPointerActive
        updateRightBarItems(animated: false)
        delegate?.onWordTranslationButtonTapped(isWordPointerActive: isWordPointerActive)
    }
}
