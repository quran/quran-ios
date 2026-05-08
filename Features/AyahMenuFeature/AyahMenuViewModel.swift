//
//  AyahMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import Crashing
#if QURAN_SYNC
    import FeaturesSupport
    import MobileSync
#endif
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
    func deleteNotes(_ notes: [QuranAnnotations.Note], verses: [AyahNumber]) async
    func showTranslation(_ verses: [AyahNumber])

    #if QURAN_SYNC
        func addSyncedNote(verses: [AyahNumber])
    #endif

    func editNote(_ note: QuranAnnotations.Note)
}

// MARK: - ViewModel

@MainActor
final class AyahMenuViewModel {
    struct Deps {
        let sourceView: UIView
        let pointInView: CGPoint
        let verses: [AyahNumber]
        let notes: [QuranAnnotations.Note]
        let noteService: NoteService
        let textRetriever: ShareableVerseTextRetriever
        let highlightColor: HighlightColor?
        #if QURAN_SYNC
            let usesSyncedNotes: Bool
            let noteCount: Int
            let syncService: SyncService?
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
        if let highlightColor = deps.highlightColor {
            return highlightColor
        }
        return highlightColor(for: deps.noteService.color(from: deps.notes))
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

    var repeatSubtitle: String {
        if deps.verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return l("ayah.menu.selected-verses")
    }

    var usesSyncedNotesIcon: Bool {
        #if QURAN_SYNC
            return deps.usesSyncedNotes
        #else
            return false
        #endif
    }

    var noteCount: Int {
        #if QURAN_SYNC
            return deps.usesSyncedNotes ? deps.noteCount : 0
        #else
            return 0
        #endif
    }

    var noteState: AyahMenuUI.NoteState {
        #if QURAN_SYNC
            if deps.usesSyncedNotes {
                return deps.highlightColor == nil ? .noHighlight : .highlighted
            }
        #endif
        if deps.highlightColor != nil {
            return containsText(deps.notes) ? .noted : .highlighted
        }
        if deps.notes.isEmpty {
            return .noHighlight
        } else if containsText(deps.notes) {
            return .noted
        }
        return .highlighted
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

    func deleteNotes() async {
        logger.info("AyahMenu: delete notes. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()
        #if QURAN_SYNC
            if deps.highlightColor != nil, !containsText(deps.notes), deps.syncService != nil {
                do {
                    try await removeSyncedHighlights()
                } catch {
                    crasher.recordError(error, reason: "Failed to remove synced highlights")
                }
                return
            }
        #endif
        await listener?.deleteNotes(deps.notes, verses: deps.verses)
    }

    func editNote() async {
        logger.info("AyahMenu: edit notes. Verses: \(deps.verses)")
        #if QURAN_SYNC
            if deps.usesSyncedNotes {
                listener?.addSyncedNote(verses: deps.verses)
                return
            }
        #endif
        let notes = deps.notes
        let color = highlightColor(for: deps.noteService.color(from: notes))
        if let note = await updateLegacyHighlight(color: color) {
            listener?.editNote(note)
        }
    }

    func updateHighlight(color: HighlightColor) async {
        logger.info("AyahMenu: update verse highlights. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()
        _ = await _updateHighlight(color: color)
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

    private func containsText(_ notes: [QuranAnnotations.Note]) -> Bool {
        notes.contains { note in
            !(note.note ?? "").isEmpty
        }
    }

    private func _updateHighlight(color: HighlightColor) async -> QuranAnnotations.Note? {
        #if QURAN_SYNC
            if deps.syncService != nil {
                do {
                    try await updateSyncedHighlight(color: color)
                    return nil
                } catch {
                    crasher.recordError(error, reason: "Failed to update synced highlights")
                    return nil
                }
            }
        #endif

        return await updateLegacyHighlight(color: color)
    }

    private func updateLegacyHighlight(color: HighlightColor) async -> QuranAnnotations.Note? {
        let quran = ReadingPreferences.shared.reading.quran
        do {
            let updatedNote = try await deps.noteService.updateHighlight(
                verses: deps.verses, color: legacyColor(for: color), quran: quran
            )
            logger.info("AyahMenu: notes updated")
            return updatedNote
        } catch {
            crasher.recordError(error, reason: "Failed to update highlights")
            return nil
        }
    }

    private func retrieveSelectedAyahText() async throws -> [String] {
        try await crasher.recordError("Failed to update highlights") {
            try await deps.textRetriever.textForVerses(deps.verses)
        }
    }

    private func highlightColor(for color: QuranAnnotations.Note.Color) -> HighlightColor {
        switch color {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }

    private func legacyColor(for color: HighlightColor) -> QuranAnnotations.Note.Color {
        switch color {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }

    #if QURAN_SYNC
        private func updateSyncedHighlight(color: HighlightColor) async throws {
            let (targetCollection, collections) = try await highlightCollection(for: color)
            let selectedAyahs = Set(deps.verses.map(AyahKey.init))
            var targetAyahs = Set<AyahKey>()

            for collection in collections where collection.highlightColor != nil {
                for bookmark in collection.bookmarks where selectedAyahs.contains(AyahKey(bookmark)) {
                    if collection.collection.localId == targetCollection.collection.localId {
                        targetAyahs.insert(AyahKey(bookmark))
                    } else {
                        try await syncService.removeAyahBookmarkFromCollection(bookmark)
                    }
                }
            }

            for verse in deps.verses where !targetAyahs.contains(AyahKey(verse)) {
                _ = try await syncService.addAyahBookmarkToCollection(
                    collectionLocalId: targetCollection.collection.localId,
                    sura: Int32(verse.sura.suraNumber),
                    ayah: Int32(verse.ayah)
                )
            }
        }

        private func removeSyncedHighlights() async throws {
            let selectedAyahs = Set(deps.verses.map(AyahKey.init))
            for collection in try await collectionsSnapshot() where collection.highlightColor != nil {
                for bookmark in collection.bookmarks where selectedAyahs.contains(AyahKey(bookmark)) {
                    try await syncService.removeAyahBookmarkFromCollection(bookmark)
                }
            }
        }

        private func highlightCollection(for color: HighlightColor) async throws -> (CollectionWithAyahBookmarks, [CollectionWithAyahBookmarks]) {
            let collections = try await collectionsSnapshot()
            if let collection = collections.first(where: { $0.collection.name == color.collectionName }) {
                return (collection, collections)
            }

            try await syncService.createCollection(named: color.collectionName)
            let updatedCollections = try await collectionsSnapshot()
            guard let collection = updatedCollections.first(where: { $0.collection.name == color.collectionName }) else {
                throw SyncedHighlightCollectionError.collectionUnavailable
            }
            return (collection, updatedCollections)
        }

        private func collectionsSnapshot() async throws -> [CollectionWithAyahBookmarks] {
            var iterator = syncService.collectionsWithBookmarksSequence().makeAsyncIterator()
            return try await iterator.next() ?? []
        }

        private var syncService: SyncService {
            guard let syncService = deps.syncService else {
                fatalError("Expected sync service when QURAN_SYNC is enabled")
            }
            return syncService
        }
    #endif
}

#if QURAN_SYNC
    private struct AyahKey: Hashable {
        init(_ bookmark: CollectionAyahBookmark) {
            sura = bookmark.sura
            ayah = bookmark.ayah
        }

        init(_ ayahNumber: AyahNumber) {
            sura = Int32(ayahNumber.sura.suraNumber)
            ayah = Int32(ayahNumber.ayah)
        }

        let sura: Int32
        let ayah: Int32
    }

    private enum SyncedHighlightCollectionError: Error {
        case collectionUnavailable
    }
#endif
