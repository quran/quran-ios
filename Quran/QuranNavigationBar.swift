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
    func onMoreButtonTapped(_ barButton: UIBarButtonItem)
}

class QuranNavigationBar {
    private let simplePersistence: SimplePersistence

    weak var delegate: QuranNavigationBarDelegate?

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

        let moreImage = #imageLiteral(resourceName: "more-horiz.png")
        let more = UIBarButtonItem(image: moreImage, style: .plain, target: self, action: #selector(onMoreTapped(_:)))
        delegate?.navigationItem.setRightBarButtonItems([more, bookmark], animated: animated)
    }

    @objc
    private func onBookmarkTapped() {
        delegate?.onBookmarkButtonTapped()
        updateRightBarItems(animated: false)
    }

    @objc
    private func onMoreTapped(_ barButton: UIBarButtonItem) {
        delegate?.onMoreButtonTapped(barButton)
    }
}
