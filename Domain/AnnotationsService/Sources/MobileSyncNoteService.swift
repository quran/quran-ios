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

public struct SyncedNotesSequence: AsyncSequence {
    public typealias Element = [QuranAnnotations.Note]

    public struct AsyncIterator: AsyncIteratorProtocol {
        init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
            var iterator = sequence.makeAsyncIterator()
            nextValue = {
                try await iterator.next()
            }
        }

        public mutating func next() async throws -> Element? {
            try await nextValue()
        }

        private let nextValue: () async throws -> Element?
    }

    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        makeIterator = {
            AsyncIterator(sequence)
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        makeIterator()
    }

    private let makeIterator: () -> AsyncIterator
}

public struct MobileSyncNoteService {
    // MARK: Lifecycle

    public init(quranDataService: QuranDataService) {
        self.quranDataService = quranDataService
    }

    // MARK: Public

    public func notesSequence(quran: Quran) -> SyncedNotesSequence {
        let sequence = quranDataService.notesSequence()
            .map { notes in
                Self.notes(from: notes, quran: quran)
            }
        return SyncedNotesSequence(sequence)
    }

    public func createNote(body: String, startAyah: AyahNumber, endAyah: AyahNumber) async throws {
        try await quranDataService.createNote(
            body: body,
            startSura: Int32(startAyah.sura.suraNumber),
            startAyah: Int32(startAyah.ayah),
            endSura: Int32(endAyah.sura.suraNumber),
            endAyah: Int32(endAyah.ayah)
        )
    }

    public func updateNote(_ note: QuranAnnotations.Note, body: String) async throws {
        try await updateNote(note, body: body, startAyah: note.startAyah, endAyah: note.endAyah)
    }

    public func updateNote(_ note: QuranAnnotations.Note, body: String, startAyah: AyahNumber, endAyah: AyahNumber) async throws {
        try await quranDataService.updateNote(
            id: note.id,
            body: body,
            startSura: Int32(startAyah.sura.suraNumber),
            startAyah: Int32(startAyah.ayah),
            endSura: Int32(endAyah.sura.suraNumber),
            endAyah: Int32(endAyah.ayah)
        )
    }

    public func removeNote(_ note: QuranAnnotations.Note) async throws {
        try await quranDataService.removeNote(id: note.id)
    }

    // MARK: Internal

    static func notes(from notes: [Note_], quran: Quran) -> [QuranAnnotations.Note] {
        notes.compactMap { note(from: $0, quran: quran) }
            .sorted { $0.modifiedDate > $1.modifiedDate }
    }

    static func note(from note: Note_, quran: Quran) -> QuranAnnotations.Note? {
        guard let start = AyahNumber(quran: quran, sura: Int(note.startSura), ayah: Int(note.startAyah)),
              let end = AyahNumber(quran: quran, sura: Int(note.endSura), ayah: Int(note.endAyah)),
              start <= end
        else {
            return nil
        }

        return QuranAnnotations.Note(
            id: note.id,
            text: note.body,
            startAyah: start,
            endAyah: end,
            modifiedDate: note.lastUpdated
        )
    }

    // MARK: Private

    private let quranDataService: QuranDataService
}
#endif
