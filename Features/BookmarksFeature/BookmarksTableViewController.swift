//
//  BookmarksTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import UIKit

class BookmarksTableViewController: ModernSingleSectionTableViewController<PageBookmark, PageBookmarkCell>, BookmarksPresentable {
    // MARK: Lifecycle

    init(interactor: BookmarksInteractor) {
        self.interactor = interactor
        let pageDS = PageBookmarkDataSource()
        super.init(dataSource: pageDS, noDataView: {
            NoDataView(
                title: l("bookmarks.no-data.title"),
                text: l("bookmarks.no-data.text"),
                image: "bookmark.fill"
            )
        })
        interactor.presenter = self
        listener = ModernSingleSectionTableListener(
            viewDidLoad: { [weak self] in
                self?.interactor.viewDidLoad()
            },
            viewWillAppear: {},
            selectItem: { [weak self] in
                self?.interactor.selectItem($0)
            },
            deleteItem: { [weak self] in
                self?.interactor.deleteItem($0)
            }
        )
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        title = lAndroid("menu_bookmarks")
        addCloudSyncInfo()
    }

    // MARK: Private

    private let interactor: BookmarksInteractor
}

private class PageBookmarkDataSource: ModernEditableBasicDataSource<PageBookmark, PageBookmarkCell> {
    override func view(with item: PageBookmark, at indexPath: IndexPath) -> PageBookmarkCell {
        let ayah = item.page.firstVerse
        let bookmarkCell = PageBookmarkCell(
            page: item.page.pageNumber,
            localizedSura: ayah.sura.localizedName(),
            arabicSuraName: ayah.sura.arabicSuraName,
            createdSince: item.creationDate.timeAgo()
        )
        return bookmarkCell
    }
}
