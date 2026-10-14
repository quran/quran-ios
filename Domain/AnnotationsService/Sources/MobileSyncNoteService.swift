#if QURAN_SYNC
//
//  MobileSyncNoteService.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
//

import Foundation
@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit
import Utilities

public struct MobileSyncNoteService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService) {
        self.quranDataService = quranDataService
    }

    // MARK: Public

    public func notesSequence(quran: Quran) -> AnyAsyncSequence<[QuranAnnotations.Note]> {
        let sequence = quranDataService.notesSequence()
            .map { notes in
                Self.notes(from: notes, quran: quran)
            }
        return .init(sequence)
    }

    public func createNote(body: String, startAyah: AyahNumber, endAyah: AyahNumber) async throws {
        try await mapTextLengthLimit {
            try await quranDataService.createNote(
                body: body,
                startSura: Int32(startAyah.sura.suraNumber),
                startAyah: Int32(startAyah.ayah),
                endSura: Int32(endAyah.sura.suraNumber),
                endAyah: Int32(endAyah.ayah)
            )
        }
    }

    /// Changes only the note's text. A note's verse range never changes.
    public func updateNote(_ note: QuranAnnotations.Note, body: String) async throws {
        try await mapTextLengthLimit {
            try await quranDataService.updateNote(id: note.id, body: body)
        }
    }

    public func removeNote(_ note: QuranAnnotations.Note) async throws {
        try await quranDataService.deleteNote(id: note.id)
    }

    // MARK: Internal

    static func notes(from notes: [MobileSync.Note], quran: Quran) -> [QuranAnnotations.Note] {
        notes.compactMap { note(from: $0, quran: quran) }
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }

    /// Maps every range of the note; a note with a range this Quran doesn't have is skipped.
    static func note(from note: MobileSync.Note, quran: Quran) -> QuranAnnotations.Note? {
        var verses = Set<AyahNumber>()
        for range in note.ranges {
            guard let start = AyahNumber(quran: quran, sura: Int(range.startSura), ayah: Int(range.startAyah)),
                  let end = AyahNumber(quran: quran, sura: Int(range.endSura), ayah: Int(range.endAyah)),
                  start <= end
            else {
                return nil
            }
            verses.formUnion(start.array(to: end))
        }
        guard !verses.isEmpty else {
            return nil
        }

        return QuranAnnotations.Note(
            id: note.id,
            text: note.body,
            verses: verses,
            modifiedDate: note.lastUpdated
        )
    }

    // MARK: Private

    private let quranDataService: QuranDataService
}
#endif
