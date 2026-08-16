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
import NotePersistence
import QuranAnnotations
import QuranKit

public struct NoteService {
    // MARK: Lifecycle

    public init(persistence: NotePersistence, analytics: AnalyticsLibrary) {
        self.persistence = persistence
        self.analytics = analytics
    }

    // MARK: Public

    #if !QURAN_SYNC
    public func color(from notes: [Note]) -> HighlightColor {
        notes.max { $0.modifiedDate < $1.modifiedDate }?.color ?? HighlightPreferences.shared.lastUsedHighlightColor
    }

    public func updateHighlight(verses: [AyahNumber], color: HighlightColor, quran: Quran) async throws -> Note {
        // update last used highlight color
        HighlightPreferences.shared.lastUsedHighlightColor = color

        analytics.highlight(verses: verses)
        let verses = verses.map(VersePersistenceModel.init)
        let persistenceModel = try await persistence.setNote(nil, verses: verses, color: color.rawValue)
        guard let note = Note(quran: quran, persistenceModel) else {
            throw NoteServiceError.invalidPersistenceModel
        }
        return note
    }

    public func setNote(_ note: String, verses: [AyahNumber], color: HighlightColor) async throws {
        // update last used highlight color
        HighlightPreferences.shared.lastUsedHighlightColor = color

        analytics.updateNote(verses: Set(verses))
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
            .map { notes in notes.compactMap { Note(quran: quran, $0) } }
            .eraseToAnyPublisher()
    }
    #endif

    // MARK: Internal

    let persistence: NotePersistence
    let analytics: AnalyticsLibrary
}

#if !QURAN_SYNC
private enum NoteServiceError: Error {
    case invalidPersistenceModel
}

private extension Note {
    init?(quran: Quran, _ note: NotePersistenceModel) {
        let verses = note.verses.compactMap {
            AyahNumber(quran: quran, sura: $0.sura, ayah: $0.ayah)
        }
        guard verses.count == note.verses.count, !verses.isEmpty else {
            return nil
        }

        self.init(
            verses: Set(verses),
            modifiedDate: note.modifiedDate,
            text: note.note,
            color: HighlightColor(rawValue: note.color) ?? .red
        )
    }
}

private extension VersePersistenceModel {
    init(_ verse: AyahNumber) {
        self.init(ayah: verse.ayah, sura: verse.sura.suraNumber)
    }
}
#endif
