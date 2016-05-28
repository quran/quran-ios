//
//  QuranPagesDataSource.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import GenericDataSources

class QuranPagesDataSource: BasicDataSource<QuranPage, QuranPageCollectionViewCell> {

    let imageService: QuranImageService
    let ayahInfoRetriever: AyahInfoRetriever

    let numberFormatter = NSNumberFormatter()

    var highlightedAyat: Set<AyahNumber> = Set()

    init(reuseIdentifier: String, imageService: QuranImageService, ayahInfoRetriever: AyahInfoRetriever) {
        self.imageService = imageService
        self.ayahInfoRetriever = ayahInfoRetriever
        super.init(reuseIdentifier: reuseIdentifier)
    }

    override func ds_collectionView(collectionView: GeneralCollectionView,
                                    configureCell cell: QuranPageCollectionViewCell,
                                    withItem item: QuranPage,
                                    atIndexPath indexPath: NSIndexPath) {

        let size = ds_collectionView(collectionView, sizeForItemAtIndexPath: indexPath)

        cell.page = item
        cell.pageLabel.text = numberFormatter.format(item.pageNumber)
        cell.suraLabel.text = Quran.nameForSura(item.startAyah.sura)
        cell.juzLabel.text = String(format: NSLocalizedString("juz2_description", tableName: "Android", comment: ""), item.juzNumber)

        cell.mainImageView.image = nil
        cell.highlightAyat(highlightedAyat)

        imageService.getImageOfPage(item.pageNumber, forSize: size) { (image) in
            guard cell.page == item else {
                return
            }
            cell.mainImageView.image = image
        }

        ayahInfoRetriever.retrieveAyahsAtPage(item.pageNumber) { (data) in
            guard cell.page == item else {
                return
            }
            cell.setAyahInfo(data.value)
        }
    }

    func removeHighlighting() {
        highlightedAyat.removeAll(keepCapacity: true)
        for cell in ds_reusableViewDelegate?.ds_visibleCells() as? [QuranPageCollectionViewCell] ?? [] {
            cell.highlightAyat(highlightedAyat)
        }
    }

    func highlightAyaht(ayat: Set<AyahNumber>) {
        highlightedAyat = ayat

        guard let ayah = ayat.first else {
            removeHighlighting()
            return
        }

        Queue.background.async {
            let page = ayah.getStartPage()

            Queue.main.async {
                let index = NSIndexPath(forItem: page - 1, inSection: 0)
                // if the cell is there, highlight the ayah.
                if let cell = self.ds_reusableViewDelegate?.ds_cellForItemAtIndexPath(index) as? QuranPageCollectionViewCell {
                    cell.highlightAyat(ayat)
                } else {
                    // scroll to the cell
                    self.ds_reusableViewDelegate?.ds_scrollToItemAtIndexPath(index, atScrollPosition: .CenteredHorizontally, animated: true)
                }
            }
        }
    }
}
