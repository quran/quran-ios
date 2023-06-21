//
//  NotesInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import Combine
import Crashing
import FeaturesSupport
import Foundation
import PromiseKit
import QuranAnnotations
import QuranKit
import ReadingService
import Utilities
import VLogging

@MainActor
protocol NotesPresentable: AnyObject {
    func setItems(_ items: [NoteUI])
    func showErrorAlert(error: Error)
}

@MainActor
final class NotesInteractor {
    struct Deps {
        let analytics: AnalyticsLibrary
        let noteService: NoteService
        let pageBookmarkService: PageBookmarkService
    }

    // MARK: Lifecycle

    init(deps: Deps) {
        self.deps = deps
    }

    // MARK: Internal

    weak var presenter: NotesPresentable?
    weak var listener: QuranNavigator?

    func viewDidLoad() {
        // Observe persistence changes
        loadNotes()
    }

    func selectItem(_ item: NoteUI) {
        logger.info("Notes: select note at \(item.note.firstVerse)")
        let page = item.note.firstVerse.page
        navigateTo(page: page)
    }

    func deleteItem(_ item: NoteUI) {
        logger.info("Notes: delete note at \(item.note.firstVerse)")
        deps.noteService.removeNotes(with: Array(item.note.verses))
            .catch(on: .main) { error in
                self.presenter?.showErrorAlert(error: error)
            }
    }

    // MARK: Private

    private let deps: Deps
    private let readingPreferences = ReadingPreferences.shared

    private var cancellables: Set<AnyCancellable> = []

    private func navigateTo(page: Page) {
        deps.analytics.openingQuran(from: .notes)
        listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
    }

    private func loadNotes() {
        readingPreferences.$reading
            .prepend(readingPreferences.reading)
            .map { [deps] reading in
                deps.noteService.notes(quran: reading.quran)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notes in
                guard let self else {
                    return
                }
                Task { @MainActor in
                    let notesUI = await self.noteUIs(with: notes)
                    self.presenter?.setItems(notesUI)
                }
            }
            .store(in: &cancellables)
    }

    private func noteUIs(with notes: [Note]) async -> [NoteUI] {
        await withTaskGroup(of: NoteUI.self) { group in
            for note in notes {
                group.addTask {
                    do {
                        let verseText = try await self.deps.noteService.textForVerses(Array(note.verses))
                        return NoteUI(note: note, verseText: verseText)
                    } catch {
                        crasher.recordError(error, reason: "NoteService.textForVerses")
                        return NoteUI(note: note, verseText: note.firstVerse.localizedName)
                    }
                }
            }

            let result = await group.collect()
            return result.sorted { $0.note.modifiedDate > $1.note.modifiedDate }
        }
    }
}
