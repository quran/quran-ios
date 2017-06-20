//
//  QuranBaseBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
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

import GenericDataSources

protocol QuranDataSourceDelegate: class {
    var lastViewedPage: Int { get }
}

class QuranBaseBasicDataSource<CellType: QuranBasePageCollectionViewCell>: BasicDataSource<QuranPage, CellType> {

    var onScrollViewWillBeginDragging: (() -> Void)?

    private let bookmarkPersistence: BookmarksPersistence

    private var highlights: [QuranHighlightType: Set<AyahNumber>] = [:] {
        didSet {
            updateHighlightsForVisibleCells()
        }
    }

    weak var delegate: QuranDataSourceDelegate?

    public init(bookmarkPersistence: BookmarksPersistence) {
        self.bookmarkPersistence = bookmarkPersistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: CellType,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {
        cell.onScrollViewWillBeginDragging = { [weak self] in
            self?.onScrollViewWillBeginDragging?()
        }
        // configure common properties
        cell.setNeedsLayout()
        cell.page = item
        for (type, ayat) in highlights {
            cell.setHighlightedVerses(ayat, forType: type)
        }

        // set bookmarked ayat
        DispatchQueue.default
            .promise2 { try self.bookmarkPersistence.retrieve(inPage: item.pageNumber) }
            .then(on: .main) { (_, ayahBookmarks) -> Void in
                cell.setHighlightedVerses(Set(ayahBookmarks.map { $0.ayah }), forType: .bookmark)
            }.cauterize(tag: "bookmarkPersistence.retrieve(inPage:)")
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        // Update the highlighting since it's something that could change
        // between the cell is configured and the cell is visible.
        if let cell = cell as? QuranBasePageCollectionViewCell {
            for (type, ayat) in highlights {
                cell.setHighlightedVerses(ayat, forType: type)
            }
        }
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>, isActive: Bool) {
        highlights[.reading] = ayat

        if let ayah = ayat.first, isActive {
            scrollToHighlightedAyaIfNeeded(ayah)
        }
    }

    func highlightSearchAyaht(_ ayat: Set<AyahNumber>, isActive: Bool) {
        highlights[.search] = ayat

        if let ayah = ayat.first, isActive {
            scrollToHighlightedAyaIfNeeded(ayah)
        }
    }

    func applicationDidBecomeActive() {
        if let ayah = highlights[.reading]?.first {
            scrollToHighlightedAyaIfNeeded(ayah)
        } else {
            if let lastPageViewed = delegate?.lastViewedPage {
                scrollTo(page: lastPageViewed)
            }
        }
    }

    private func scrollToHighlightedAyaIfNeeded(_ ayah: AyahNumber) {
        DispatchQueue.default
            .promise2(execute: ayah.getStartPage)
            .then(on: .main) { self.scrollTo(page: $0) }
            .cauterize(tag: "Never.getStartPage")
    }

    private func scrollTo(page: Int) {
        guard let delegate = ds_reusableViewDelegate else {
            return
        }
        let indexPath = IndexPath(item: page - 1, section: 0)

        // if the cell is there, highlight the ayah.
        if !delegate.ds_indexPathsForVisibleItems().contains(indexPath) {
            // scroll to the cell
            ds_reusableViewDelegate?.ds_scrollView.endEditing(false)
            if indexPath.section < delegate.ds_numberOfSections() && indexPath.item < delegate.ds_numberOfItems(inSection: indexPath.section) {
                delegate.ds_scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }

    private func updateHighlightsForVisibleCells() {
        for cell in ds_reusableViewDelegate?.ds_visibleCells() ?? [] {
            if let cell = cell as? QuranBasePageCollectionViewCell {
                for (type, ayat) in highlights {
                    cell.setHighlightedVerses(ayat, forType: type)
                }
            }
        }
    }
}
