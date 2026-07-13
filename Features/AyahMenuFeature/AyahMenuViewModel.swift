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
import BookmarksFeature
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
    func showTranslation(_ verses: [AyahNumber])
    func showNoteEditor(for verses: [AyahNumber]) async
    func deleteNotes(in verses: [AyahNumber]) async
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
        #if QURAN_SYNC
        let highlightVerses: [AyahNumber: HighlightColor]
        let highlightCollections: [AyahBookmarkCollection]
        let ayahBookmarkCollectionService: AyahBookmarkCollectionService
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
        return selectedHighlightColor ?? HighlightPreferences.shared.lastUsedHighlightColor
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

    var repeatSubtitle: String {
        if deps.verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return l("ayah.menu.selected-verses")
    }

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

    func deleteNotes() async {
        logger.info("AyahMenu: delete notes. Verses: \(deps.verses)")
        listener?.dismissAyahMenu()
        await listener?.deleteNotes(in: deps.verses)
    }

    func editNote() async {
        logger.info("AyahMenu: edit notes. Verses: \(deps.verses)")
        await listener?.showNoteEditor(for: deps.verses)
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

    #if QURAN_SYNC
    private var selectedHighlightColor: HighlightColor? {
        let colors = deps.verses.compactMap { deps.highlightVerses[$0] }
        guard colors.count == deps.verses.count else {
            return nil
        }
        let uniqueColors = Set(colors)
        return uniqueColors.count == 1 ? uniqueColors.first : nil
    }
    #endif

    // MARK: - Helper

    #if !QURAN_SYNC
    private func containsText(_ notes: [QuranAnnotations.Note]) -> Bool {
        notes.contains { note in
            !(note.text ?? "").isEmpty
        }
    }
    #endif

    private func _updateHighlight(color: HighlightColor) async -> QuranAnnotations.Note? {
        #if QURAN_SYNC
        do {
            try await updateSyncedHighlight(color: color)
            return nil
        } catch {
            crasher.recordError(error, reason: "Failed to update synced highlights")
            return nil
        }
        #else
        return await updateLegacyHighlight(color: color)
        #endif
    }

    #if !QURAN_SYNC
    private func updateLegacyHighlight(color: HighlightColor) async -> QuranAnnotations.Note? {
        let quran = ReadingPreferences.shared.reading.quran
        do {
            let updatedNote = try await deps.noteService.updateHighlight(
                verses: deps.verses, color: color, quran: quran
            )
            logger.info("AyahMenu: notes updated")
            return updatedNote
        } catch {
            crasher.recordError(error, reason: "Failed to update highlights")
            return nil
        }
    }
    #endif

    private func retrieveSelectedAyahText() async throws -> [String] {
        try await crasher.recordError("Failed to update highlights") {
            try await deps.textRetriever.textForVerses(deps.verses)
        }
    }

    #if QURAN_SYNC
    private func updateSyncedHighlight(color: HighlightColor) async throws {
        HighlightPreferences.shared.lastUsedHighlightColor = color

        let collections = deps.highlightCollections.filter {
            if case .colored = $0.kind {
                return true
            }
            return false
        }
        guard let targetCollection = collections.first(where: {
            $0.kind == .colored(color)
        }) else {
            throw AyahMenuError.highlightCollectionUnavailable
        }
        let service = deps.ayahBookmarkCollectionService
        let otherCollections = collections.filter {
            $0.collection.localId != targetCollection.collection.localId
        }
        try await service.addAyahBookmarksIfNeeded(
            deps.verses,
            to: targetCollection
        )
        try await service.removeAyahBookmarksIfNeeded(
            deps.verses,
            from: otherCollections
        )
    }
    #endif
}

#if QURAN_SYNC
private enum AyahMenuError: Error {
    case highlightCollectionUnavailable
}
#endif
