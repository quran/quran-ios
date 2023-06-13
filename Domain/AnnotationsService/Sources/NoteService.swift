//
//  NoteService.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/21/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import Combine
import Foundation
import Localization
import NotePersistence
import Preferences
import PromiseKit
import QuranAnnotations
import QuranKit
import QuranTextKit

public struct NoteService {
    let persistence: NotePersistence
    let textService: QuranTextDataService
    let analytics: AnalyticsLibrary

    public init(persistence: NotePersistence, textService: QuranTextDataService, analytics: AnalyticsLibrary) {
        self.persistence = persistence
        self.textService = textService
        self.analytics = analytics
    }

    private static let defaultLastUsedNoteHighlightColor = Note.Color.red
    private static let lastUsedNoteHighlightColorKey = PreferenceKey<Int>(
        key: "lastUsedNoteHighlightColor",
        defaultValue: defaultLastUsedNoteHighlightColor.rawValue
    )

    @TransformedPreference(lastUsedNoteHighlightColorKey, transformer: .rawRepresentable(defaultValue: defaultLastUsedNoteHighlightColor))
    private var lastUsedHighlightColor: Note.Color

    public func color(from notes: [Note]) -> Note.Color {
        notes.max { $0.modifiedDate < $1.modifiedDate }?.color ?? lastUsedHighlightColor
    }

    public func updateHighlight(verses: [AyahNumber], color: Note.Color, quran: Quran) -> Promise<Note> {
        // update last used highlight color
        lastUsedHighlightColor = color

        analytics.highlight(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        return persistence.setNote(nil, verses: verses, color: color.rawValue)
            .map { Note(quran: quran, $0) }
    }

    public func setNote(_ note: String, verses: Set<AyahNumber>, color: Note.Color) -> Promise<Void> {
        // update last used highlight color
        lastUsedHighlightColor = color

        analytics.updateNote(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        return persistence.setNote(note, verses: Array(verses), color: color.rawValue)
            .map { _ in () }
    }

    public func removeNotes(with verses: [AyahNumber]) -> Promise<Void> {
        analytics.unhighlight(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        return persistence.removeNotes(with: verses)
            .map { _ in () }
    }

    public func notes(quran: Quran) -> AnyPublisher<[Note], Never> {
        persistence.notes()
            .map { notes in notes.map { Note(quran: quran, $0) } }
            .eraseToAnyPublisher()
    }

    private func textDictionaryForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: String] {
        let translatedVerses = try await textService.textForVerses(verses, translations: [])
        return Dictionary(zip(verses, translatedVerses.verses).map { ($0, $1.arabicText) }, uniquingKeysWith: { x, _ in x })
    }

    public func textForVerses(_ verses: [AyahNumber]) async throws -> String {
        let versesWithText = try await textDictionaryForVerses(verses)
        let sortedVerses = verses.sorted()
        let versesText = sortedVerses.compactMap { verse in versesWithText[verse].map { (verse, $0) } }
        let combinedVersesText = versesText.map { $0.1 + " \(NumberFormatter.arabicNumberFormatter.format($0.0.ayah))" }
            .joined(separator: " ")
        return combinedVersesText
    }
}

private extension Note {
    init(quran: Quran, _ note: NotePersistenceModel) {
        self.init(verses: Set(note.verses.map { AyahNumber(quran: quran, $0) }),
                  modifiedDate: note.modifiedDate,
                  note: note.note,
                  color: Note.Color(rawValue: note.color) ?? .red)
    }
}

private extension AyahNumber {
    init(quran: Quran, _ other: VersePersistenceModel) {
        self.init(quran: quran, sura: other.sura, ayah: other.ayah)!
    }
}

private extension VersePersistenceModel {
    init(_ verse: AyahNumber) {
        self.init(ayah: verse.ayah, sura: verse.sura.suraNumber)
    }
}
