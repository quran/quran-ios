//
//  AyahMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import Crashing
import Foundation
import Localization
import NoorUI
import QuranAnnotations
import QuranAudioKit
import QuranKit
import QuranTextKit
import ReadingService
import UIKit
import Utilities
import VLogging

@MainActor
public protocol AyahMenuListener: AnyObject {
    func dismissAyahMenu()

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool)

    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint)
    func deleteNotes(_ notes: [Note], verses: [AyahNumber]) async
    func showTranslation(_ verses: [AyahNumber])

    func editNote(_ note: Note)
}

// MARK: - ViewModel

@MainActor
final class AyahMenuViewModel {
    struct Deps {
        let sourceView: UIView
        let pointInView: CGPoint
        let verses: [AyahNumber]
        let notes: [Note]
        let noteService: NoteService
        let textRetriever: ShareableVerseTextRetriever
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

    var highlightingColor: Note.Color { deps.noteService.color(from: deps.notes) }

    var playSubtitle: String {
        if deps.verses.count > 1 { // multiple verses selected
            return l("ayah.menu.selected-verses")
        }
        switch audioPreferences.audioEnd {
        case .juz: return l("ayah.menu.play-end-juz")
        case .sura: return l("ayah.menu.play-end-surah")
        case .page: return l("ayah.menu.play-end-page")
        }
    }

    var repeatSubtitle: String {
        if deps.verses.count == 1 {
            return l("ayah.menu.selected-verse")
        }
        return l("ayah.menu.selected-verses")
    }

    var noteState: AyahMenuUI.NoteState {
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
        await listener?.deleteNotes(deps.notes, verses: deps.verses)
    }

    func editNote() async {
        logger.info("AyahMenu: edit notes. Verses: \(deps.verses)")
        let notes = deps.notes
        let color = deps.noteService.color(from: notes)
        if let note = await _updateHighlight(color: color) {
            listener?.editNote(note)
        }
    }

    func updateHighlight(color: Note.Color) async {
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
                listener?.shareText(lines, in: self.deps.sourceView, at: self.deps.pointInView)
            }
        }
    }

    // MARK: Private

    private let audioPreferences = AudioPreferences.shared

    private let deps: Deps

    // MARK: - Helper

    private func containsText(_ notes: [Note]) -> Bool {
        notes.contains { note in
            !(note.note ?? "").isEmpty
        }
    }

    private func _updateHighlight(color: Note.Color) async -> Note? {
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

    private func retrieveSelectedAyahText() async throws -> [String] {
        try await crasher.recordError("Failed to update highlights") {
            try await deps.textRetriever.textForVerses(deps.verses)
        }
    }
}
