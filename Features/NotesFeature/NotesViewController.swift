//
//  NotesViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import QuranKit
import UIKit
import UIx

final class NotesViewController: ModernSingleSectionTableViewController<NoteUI, NoteCell>, NotesPresentable {
    // MARK: Lifecycle

    init(interactor: NotesInteractor) {
        self.interactor = interactor
        let notesDS = NoteDataSource()
        super.init(dataSource: notesDS, noDataView: {
            NoDataView(
                title: l("notes.no-data.title"),
                text: l("notes.no-data.text"),
                image: "text.badge.star"
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
                await self?.interactor.deleteItem($0)
            }
        )
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        title = l("tab.notes")
        addCloudSyncInfo()
    }

    // MARK: Private

    private let interactor: NotesInteractor
}

private class NoteDataSource: ModernEditableBasicDataSource<NoteUI, NoteCell> {
    override func view(with item: NoteUI, at indexPath: IndexPath) -> NoteCell {
        let page = item.note.firstVerse.page
        return NoteCell(
            page: page.pageNumber,
            localizedVerse: item.note.firstVerse.localizedName,
            arabicSuraName: item.note.firstVerse.sura.arabicSuraName,
            versesCount: item.note.verses.count,
            ayahText: item.verseText,
            note: item.note.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            createdSince: item.note.modifiedDate.timeAgo(),
            color: item.note.color
        )
    }
}
