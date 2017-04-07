//
//  QuranBaseBasicDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/4/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import GenericDataSources

protocol QuranDataSourceDelegate: class {
    var lastViewedPage: Int { get }
}

class QuranBaseBasicDataSource<CellType: QuranBasePageCollectionViewCell>: BasicDataSource<QuranPage, CellType> {

    private let bookmarkPersistence: BookmarksPersistence

    private var highlightedAyat: Set<AyahNumber> = Set()

    weak var delegate: QuranDataSourceDelegate?

    public init(bookmarkPersistence: BookmarksPersistence) {
        self.bookmarkPersistence = bookmarkPersistence
        super.init()
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: CellType,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {
        // configure common properties
        cell.setNeedsLayout()
        cell.page = item
        cell.setHighlightedVerses(highlightedAyat, forType: .reading)

        // set bookmarked ayat
        DispatchQueue.global()
            .promise { try self.bookmarkPersistence.retrieve(inPage: item.pageNumber) }
            .then(on: .main) { (_, ayahBookmarks) -> Void in
                cell.setHighlightedVerses(Set(ayahBookmarks.map { $0.ayah }), forType: .bookmark)
            }.cauterize(tag: "bookmarkPersistence.retrieve(inPage:)")
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
        // Update the highlighting since it's something that could change
        // between the cell is configured and the cell is visible.
        (cell as? QuranBasePageCollectionViewCell)?.setHighlightedVerses(highlightedAyat, forType: .reading)
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>, isActive: Bool) {
        highlightedAyat = ayat

        // update highlighting for all cells
        for cell in ds_reusableViewDelegate?.ds_visibleCells() ?? [] {
            (cell as? QuranBasePageCollectionViewCell)?.setHighlightedVerses(highlightedAyat, forType: .reading)
        }

        if let ayah = ayat.first, isActive {
            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
        }
    }

    func applicationDidBecomeActive() {
        if let ayah = highlightedAyat.first {
            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
        } else {
            if let lastPageViewed = delegate?.lastViewedPage {
                scrollTo(page: lastPageViewed)
            }
        }
    }

    private func scrollToHighlightedAyaIfNeeded(_ ayah: AyahNumber, ayaht: Set<AyahNumber>) {
        DispatchQueue.global()
            .promise(execute: ayah.getStartPage)
            .then(on: .main) { self.scrollTo(page: $0) }
            .cauterize(tag: "Never.getStartPage")
    }

    private func scrollTo(page: Int) {
        let indexPath = IndexPath(item: page - 1, section: 0)

        // if the cell is there, highlight the ayah.
        if !(ds_reusableViewDelegate?.ds_indexPathsForVisibleItems().contains(indexPath) ?? false) {
            // scroll to the cell
            ds_reusableViewDelegate?.ds_scrollView.endEditing(false)
            ds_reusableViewDelegate?.ds_scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}
