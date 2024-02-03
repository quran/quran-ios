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
import QuranAnnotations
import QuranKit
import QuranText
import QuranTextKit

public struct NoteService {
    // MARK: Lifecycle

    public init(persistence: NotePersistence, textService: QuranTextDataService, analytics: AnalyticsLibrary) {
        self.persistence = persistence
        self.textService = textService
        self.analytics = analytics
    }

    // MARK: Public

    public func color(from notes: [Note]) -> Note.Color {
        notes.max { $0.modifiedDate < $1.modifiedDate }?.color ?? lastUsedHighlightColor
    }

    public func updateHighlight(verses: [AyahNumber], color: Note.Color, quran: Quran) async throws -> Note {
        // update last used highlight color
        lastUsedHighlightColor = color

        analytics.highlight(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        let persistenceModel = try await persistence.setNote(nil, verses: verses, color: color.rawValue)
        return Note(quran: quran, persistenceModel)
    }

    public func setNote(_ note: String, verses: Set<AyahNumber>, color: Note.Color) async throws {
        // update last used highlight color
        lastUsedHighlightColor = color

        analytics.updateNote(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        _ = try await persistence.setNote(note, verses: Array(verses), color: color.rawValue)
    }

    public func removeNotes(with verses: [AyahNumber]) async throws {
        analytics.unhighlight(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        _ = try await persistence.removeNotes(with: verses)
    }

    public func notes(quran: Quran) -> AnyPublisher<[Note], Never> {
        persistence.notes()
            .map { notes in notes.map { Note(quran: quran, $0) } }
            .eraseToAnyPublisher()
    }

    public func textForVerses(_ verses: [AyahNumber]) async throws -> String {
        let versesWithText = try await textDictionaryForVerses(verses)
        let sortedVerses = verses.sorted()
        let versesText = sortedVerses.compactMap { verse in versesWithText[verse].map { (verse, $0) } }
        let combinedVersesText = versesText.map { $0.1 + " \(NumberFormatter.arabicNumberFormatter.format($0.0.ayah))" }
            .joined(separator: " ")
        return combinedVersesText
    }

    // MARK: Internal

    let persistence: NotePersistence
    let textService: QuranTextDataService
    let analytics: AnalyticsLibrary

    // MARK: Private

    private static let defaultLastUsedNoteHighlightColor = Note.Color.red
    private static let lastUsedNoteHighlightColorKey = PreferenceKey<Int>(
        key: "lastUsedNoteHighlightColor",
        defaultValue: defaultLastUsedNoteHighlightColor.rawValue
    )

    @TransformedPreference(lastUsedNoteHighlightColorKey, transformer: .rawRepresentable(defaultValue: defaultLastUsedNoteHighlightColor))
    private var lastUsedHighlightColor: Note.Color

    private func textDictionaryForVerses(_ verses: [AyahNumber]) async throws -> [AyahNumber: String] {
        let translatedVerses: TranslatedVerses = try await textService.textForVerses(verses, translations: [])
        return Dictionary(zip(verses, translatedVerses.verses).map { ($0, $1.arabicText) }, uniquingKeysWith: { x, _ in x })
    }
}

private extension Note {
    init(quran: Quran, _ note: NotePersistenceModel) {
        self.init(
            verses: Set(note.verses.map { AyahNumber(quran: quran, $0) }),
            modifiedDate: note.modifiedDate,
            note: note.note,
            color: Note.Color(rawValue: note.color) ?? .red
        )
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
