//
//  QuranTranslationsDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranTranslationsDataSource: BasicDataSource<QuranPage, QuranTranslationPageCollectionViewCell>,
        QuranBasicDataSourceRepresentable, QuranPageCollectionCellDelegate {

    private let imageService: AnyCacheableService<Int, UIImage>
    private let ayahInfoRetriever: AyahInfoRetriever
    private let bookmarkPersistence: BookmarksPersistence

    private let numberFormatter = NumberFormatter()

    private var highlightedAyat: Set<AyahNumber> = Set()

    weak var delegate: QuranDataSourceDelegate?

    init(reuseIdentifier: String,
         imageService: AnyCacheableService<Int, UIImage>,
         ayahInfoRetriever: AyahInfoRetriever,
         bookmarkPersistence: BookmarksPersistence) {
        self.bookmarkPersistence = bookmarkPersistence
        self.imageService        = imageService
        self.ayahInfoRetriever   = ayahInfoRetriever
        super.init(reuseIdentifier: reuseIdentifier)
    }

//    override func ds_collectionView(_ collectionView: GeneralCollectionView,
//                                    configure cell: QuranTranslationPageCollectionViewCell,
//                                    with item: QuranPage,
//                                    at indexPath: IndexPath) {
//
//        cell.cellDelegate = self
//        cell.highlightingView.bookmarkPersistence = bookmarkPersistence
//
//        cell.page = item
//        cell.pageLabel.text = numberFormatter.format(NSNumber(value: item.pageNumber))
//        cell.suraLabel.text = Quran.nameForSura(item.startAyah.sura)
//        cell.juzLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), item.juzNumber)
//        cell.highlightAyat(highlightedAyat)
//
//        // set the page image
//        cell.mainImageView.image = nil
//        let size = ds_collectionView(collectionView, sizeForItemAt: indexPath)
//        imageService.getImageOfPage(item.pageNumber, forSize: size) { [weak cell] (image) in
//            guard cell?.page == item else { return }
//            cell?.mainImageView.image = image
//        }
//
//        // set the ayah dimensions
//        ayahInfoRetriever.retrieveAyahsAtPage(item.pageNumber) { [weak cell] (data) in
//            guard cell?.page == item else { return }
//            cell?.setAyahInfo(data.value)
//        }
//
//        // set bookmarked ayat
//        DispatchQueue.bookmarks
//            .promise { try self.bookmarkPersistence.retrieve(inPage: item.pageNumber) }
//            .then(on: .main) { (_, ayahBookmarks) -> Void in
//                cell.highlightingView.highlights[.bookmark] = Set(ayahBookmarks.map { $0.ayah })
//            }.cauterize(tag: "bookmarkPersistence.retrieve(inPage:)")
//    }
//
//    override func ds_collectionView(_ collectionView: GeneralCollectionView, willDisplay cell: ReusableCell, forItemAt indexPath: IndexPath) {
//        // Update the highlighting since it's something that could change
//        // between the cell is configured and the cell is visible.
//        (cell as? QuranTranslationPageCollectionViewCell)?.highlightAyat(highlightedAyat)
//    }

    func highlightAyaht(_ ayat: Set<AyahNumber>) {
//        highlightedAyat = ayat
//
//        // update highlighting for all cells
//        if let visibleCells = self.ds_reusableViewDelegate?.ds_visibleCells() as? [QuranTranslationPageCollectionViewCell] {
//            visibleCells.forEach { $0.highlightAyat(highlightedAyat) }
//        }
//
//        if let ayah = ayat.first {
//            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
//        }
    }

    func applicationDidBecomeActive() {
//        if let ayah = highlightedAyat.first {
//            scrollToHighlightedAyaIfNeeded(ayah, ayaht: highlightedAyat)
//        } else {
//            if let lastPageViewed = delegate?.lastViewedPage() {
//                scrollTo(page: lastPageViewed)
//            }
//        }
    }

//    private func scrollTo(page: Int) {
//        let indexPath = IndexPath(item: page - 1, section: 0)
//
//        // if the cell is there, highlight the ayah.
//        if !(ds_reusableViewDelegate?.ds_indexPathsForVisibleItems().contains(indexPath) ?? false) {
//            // scroll to the cell
//            ds_reusableViewDelegate?.ds_scrollView.endEditing(false)
//            ds_reusableViewDelegate?.ds_scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        }
//    }
//
//    private func scrollToHighlightedAyaIfNeeded(_ ayah: AyahNumber, ayaht: Set<AyahNumber>) {
//        DispatchQueue.global()
//            .promise(execute: ayah.getStartPage)
//            .then(on: .main) { self.scrollTo(page: $0) }
//            .cauterize(tag: "Never.getStartPage")
//    }

    func quranPageCollectionCell(_ collectionCell: UICollectionViewCell, didSelectAyahTextToShare ayahText: String) {
        delegate?.share(ayahText: ayahText)
    }
}
