//
//  AyahMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import Crashing
import Localization
import NoorUI
import QuranAnnotations
import QuranAudioKit
import QuranKit
import QuranTextKit
import ReadingService
import UIKit
import VLogging

@MainActor
public protocol AyahMenuListener: AnyObject {
    func dismissAyahMenu()

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool)

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint)
    func showTranslation(_ verses: [AyahNumber])
    func showBookmarkEditor(for verses: [AyahNumber])
    func showNoteEditor(for verses: [AyahNumber]) async
    func deleteNotes(in verses: [AyahNumber]) async
    #if QURAN_SYNC
    func setReadingBookmark(at ayah: AyahNumber, replacing bookmark: ReadingPositionBookmark?) async
    func removeReadingBookmark(_ bookmark: ReadingPositionBookmark) async
    #endif
}

// MARK: - ViewModel

@MainActor
final class AyahMenuViewModel {
    struct Deps {
        let sourceView: UIView
        let pointInView: CGPoint
        let verses: [AyahNumber]
        let textRetriever: ShareableVerseTextRetriever
        let notes: [QuranAnnotations.Note]
        let highlightVerses: [AyahNumber: HighlightColor]
        let bookmarkedVerses: Set<AyahNumber>
        #if QURAN_SYNC
        let readingBookmark: ReadingPositionBookmark?
        #else
        let noteService: NoteService
        #endif
        let quranContentStatePreferences = QuranContentStatePreferences.shared
    }

    // MARK: Lifecycle

    init(deps: Deps) {
        self.deps = deps
    }

    // MARK: Internal

    weak var listener: AyahMenuListener?

    var isTranslationView: Bool {
        deps.quranContentStatePreferences.quranMode == .translation
    }

    var highlightingColor: HighlightColor {
        #if QURAN_SYNC
        return HighlightPreferences.shared.lastUsedHighlightColor
        #else
        return deps.noteService.color(from: deps.notes)
        #endif
    }

    var playSubtitle: String {
        if deps.verses.count > 1 { // multiple verses selected
            return l("ayah.menu.selected-verses")
        }
        switch audioPreferences.audioEnd {
        case .juz: return l("ayah.menu.play-end-juz")
        case .sura: return l("ayah.menu.play-end-surah")
        case .page: return l("ayah.menu.play-end-page")
        case .quran: return l("ayah.menu.play-end-quran")
        }
    }

    var bookmarkTitle: String {
        lFormat("bookmarks.editor.title", deps.verses.count)
    }

    var bookmarkState: AyahMenuUI.BookmarkState {
        let colors = deps.verses.compactMap { deps.highlightVerses[$0] }
        guard !colors.isEmpty else {
            let selectedVerses = Set(deps.verses)
            return selectedVerses.isDisjoint(with: deps.bookmarkedVerses) ? .unhighlighted : .bookmarked
        }
        guard colors.count == deps.verses.count, Set(colors).count == 1, let color = colors.first else {
            return .partiallyHighlighted
        }
        return .highlighted(color)
    }

    var repeatSubtitle: String {
        if deps.verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return l("ayah.menu.selected-verses")
    }

    #if QURAN_SYNC
    var readingBookmarkState: AyahMenuUI.ReadingBookmarkState {
        guard deps.verses.count == 1, let ayah = deps.verses.first else {
            return .disabled(message: l("ayah.menu.reading-bookmark.single-ayah-only"))
        }
        guard let readingBookmark = deps.readingBookmark else {
            return .unset
        }
        if readingBookmark.isAt(ayah) {
            return .current
        }
        return .elsewhere(location: readingBookmarkLocation(readingBookmark))
    }
    #endif

    var usesSyncedNotesIcon: Bool {
        #if QURAN_SYNC
        return true
        #else
        return false
        #endif
    }

    var noteState: AyahMenuUI.NoteState {
        #if QURAN_SYNC
        return deps.notes.isEmpty ? .noHighlight : .noted
        #else
        if deps.notes.isEmpty {
            return .noHighlight
        } else if containsText(deps.notes) {
            return .noted
        }
        return .highlighted
        #endif
    }

    // MARK: - Items & Actions

    func play() {
        logger.info("AyahMenu: play tapped. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()

        let verses = deps.verses
        let lastVerse = verses.count == 1 ? nil : verses.last
        listener?.playAudio(deps.verses[0], to: lastVerse, repeatVerses: false)
    }

    func repeatVerses() {
        logger.info("AyahMenu: repeat verses tapped. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()

        let verses = deps.verses
        listener?.playAudio(verses[0], to: verses.last, repeatVerses: true)
    }

    func bookmark() {
        logger.info("AyahMenu: bookmark tapped. Verses: \(deps.verses)")
        listener?.showBookmarkEditor(for: deps.verses)
    }

    #if QURAN_SYNC
    func setReadingBookmark() async {
        guard deps.verses.count == 1, let ayah = deps.verses.first else {
            return
        }
        logger.info("AyahMenu: set reading bookmark. Ayah: \(ayah)")
        await listener?.setReadingBookmark(at: ayah, replacing: deps.readingBookmark)
    }

    func removeReadingBookmark() async {
        guard deps.verses.count == 1,
              let ayah = deps.verses.first,
              let readingBookmark = deps.readingBookmark,
              readingBookmark.isAt(ayah)
        else {
            return
        }
        logger.info("AyahMenu: remove reading bookmark. Bookmark: \(readingBookmark)")
        await listener?.removeReadingBookmark(readingBookmark)
    }
    #endif

    func deleteNotes() async {
        logger.info("AyahMenu: delete notes. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()
        await listener?.deleteNotes(in: deps.verses)
    }

    func editNote() async {
        logger.info("AyahMenu: edit notes. Verses: \(deps.verses)")
        await listener?.showNoteEditor(for: deps.verses)
    }

    func showTranslation() {
        logger.info("AyahMenu: showTranslation. Verses: \(deps.verses)")
        listener?.showTranslation(deps.verses)
    }

    func copy() {
        logger.info("AyahMenu: copy. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()
        Task {
            if let lines = try? await retrieveSelectedAyahText() {
                let pasteBoard = UIPasteboard.general
                pasteBoard.string = lines.joined(separator: "\n")
            }
        }
    }

    func share() {
        logger.info("AyahMenu: share. Verses: \(deps.verses)")
        Task {
            if let lines = try? await retrieveSelectedAyahText() {
                let withNewLines = lines.joined(separator: "\n")
                listener?.shareText([withNewLines], in: self.deps.sourceView, at: self.deps.pointInView)
            }
        }
    }

    // MARK: Private

    private let audioPreferences = AudioPreferences.shared

    private let deps: Deps

    // MARK: - Helper

    #if !QURAN_SYNC
    private func containsText(_ notes: [QuranAnnotations.Note]) -> Bool {
        notes.contains { note in
            !(note.text ?? "").isEmpty
        }
    }
    #endif

    private func retrieveSelectedAyahText() async throws -> [String] {
        try await crasher.recordError("Failed to update highlights") {
            try await deps.textRetriever.textForVerses(deps.verses)
        }
    }

    #if QURAN_SYNC
    private func readingBookmarkLocation(_ bookmark: ReadingPositionBookmark) -> MultipartText {
        let location: MultipartText
        switch bookmark.location {
        case .ayah(let ayah):
            let localizedLocation = "\(ayah.sura.localizedName()) \(ayah.sura.localizedSuraNumber):\(NumberFormatter.shared.format(ayah.ayah))"
            location = "\(localizedLocation) \(sura: ayah.sura.arabicSuraName)"
        case .page(let page):
            location = "\(page.localizedName)"
        }

        return .localizedFormat("ayah.menu.reading-bookmark.move-here", location)
    }
    #endif
}
