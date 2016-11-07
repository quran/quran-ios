//
//  QuranPagesDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

protocol QuranPagesDataSourceDelegate: class {
    func share(ayahText: String, from cell: QuranPageCollectionViewCell)
    func lastViewedPage() -> Int
}

class QuranPagesDataSource: BasicDataSource<QuranPage, QuranPageCollectionViewCell>, QuranPageCollectionCellDelegate {

    private let imageService: QuranImageService
    private let ayahInfoRetriever: AyahInfoRetriever
    private let bookmarkPersistence: BookmarksPersistence

    private let numberFormatter = NumberFormatter()

    private var highlightedAyat: Set<AyahNumber> = Set()

    weak var delegate: QuranPagesDataSourceDelegate?

    init(reuseIdentifier: String,
         imageService: QuranImageService,
         ayahInfoRetriever: AyahInfoRetriever,
         bookmarkPersistence: BookmarksPersistence) {
        self.imageService = imageService
        self.ayahInfoRetriever = ayahInfoRetriever
        self.bookmarkPersistence = bookmarkPersistence
        super.init(reuseIdentifier: reuseIdentifier)

        NotificationCenter.default.addObserver(self, selector: #selector(applicationBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func ds_collectionView(_ collectionView: GeneralCollectionView,
                                    configure cell: QuranPageCollectionViewCell,
                                    with item: QuranPage,
                                    at indexPath: IndexPath) {

        cell.cellDelegate = self
        cell.highlightingView.bookmarkPersistence = bookmarkPersistence

        cell.page = item
        cell.pageLabel.text = numberFormatter.format(NSNumber(value: item.pageNumber))
        cell.suraLabel.text = Quran.nameForSura(item.startAyah.sura)
        cell.juzLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), item.juzNumber)
        cell.highlightAyat(highlightedAyat)

        // set the page image
        cell.mainImageView.image = nil
        let size = ds_collectionView(collectionView, sizeForItemAt: indexPath)
        imageService.getImageOfPage(item.pageNumber, forSize: size) { [weak cell] (image) in
            guard cell?.page == item else { return }
            cell?.mainImageView.image = image
        }

        // set the ayah dimensions
        ayahInfoRetriever.retrieveAyahsAtPage(item.pageNumber) { [weak cell] (data) in
            guard cell?.page == item else { return }
            cell?.setAyahInfo(data.value)
        }

        // set bookmarked ayat
        Queue.bookmarks.asyncSuccess({ try self.bookmarkPersistence.retrieve(inPage: item.pageNumber) }) { [weak cell] _, ayahBookmarks in
            guard cell?.page == item else { return }
            cell?.highlightingView.highlights[.bookmark] = Set(ayahBookmarks.map { $0.ayah })
        }
    }

    @objc (collectionView:willDisplayCell:forItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Update the highlighting since it's something that could change
        // between the cell is configured and the cell is visible.
        (cell as? QuranPageCollectionViewCell)?.highlightAyat(highlightedAyat)
    }

    func highlightAyaht(_ ayat: Set<AyahNumber>) {
        highlightedAyat = ayat

        // update highlighting for all cells
        if let visibleCells = self.ds_reusableViewDelegate?.ds_visibleCells() as? [QuranPageCollectionViewCell] {
            visibleCells.forEach { $0.highlightAyat(highlightedAyat) }
        }


        if let ayah = ayat.first {
            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
        }
    }

    @objc private func applicationBecomeActive() {
        if let ayah = highlightedAyat.first {
            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
        } else {
            if let lastPageViewed = delegate?.lastViewedPage() {
                scrollTo(page: lastPageViewed)
            }
        }
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

    private func scrollToHighlightedAyaIfNeeded(_ ayah: AyahNumber, ayaht: Set<AyahNumber>) {
        Queue.background.async({ ayah.getStartPage() }) {
            self.scrollTo(page: $0)
        }
    }

    func quranPageCollectionCell(_ collectionCell: QuranPageCollectionViewCell, didSelectAyahTextToShare ayahText: String) {
        delegate?.share(ayahText: ayahText, from: collectionCell)
    }
}
