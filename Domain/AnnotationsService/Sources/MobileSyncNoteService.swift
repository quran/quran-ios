#if QURAN_SYNC
    //
    //  MobileSyncNoteService.swift
    //
    //  Created by Ahmed Nabil on 2026-05-16.
    //

    import Analytics
    import Foundation
    @preconcurrency import MobileSync
    import QuranKit
    import QuranTextKit

    public struct SyncedNote: Equatable, Identifiable, Sendable {
        public let localId: String
        public let body: String
        public let verses: [AyahNumber]
        public let modifiedDate: Date

        public var id: String { localId }

        public var firstVerse: AyahNumber { verses[0] }
    }

    public struct SyncedNotesSequence: AsyncSequence {
        public typealias Element = [SyncedNote]

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

    public struct MobileSyncNoteService: @unchecked Sendable {
        // MARK: Lifecycle

        public init(syncService: SyncService, textService: QuranTextDataService, analytics: AnalyticsLibrary) {
            self.syncService = syncService
            self.textService = textService
            self.analytics = analytics
        }

        // MARK: Public

        public static let minimumBodyLength = 6

        public func notesSequence(quran: Quran) -> SyncedNotesSequence {
            let sequence = syncService.notesSequence()
                .map { notes in
                    Self.notes(from: notes, quran: quran)
                }
            return SyncedNotesSequence(sequence)
        }

        public func createNote(body: String, verses: [AyahNumber]) async throws {
            guard let range = versesRange(verses) else {
                return
            }

            analytics.updateNote(verses: Set(verses))
            try await syncService.createNote(
                body: body,
                startSura: Int32(range.start.sura.suraNumber),
                startAyah: Int32(range.start.ayah),
                endSura: Int32(range.end.sura.suraNumber),
                endAyah: Int32(range.end.ayah)
            )
        }

        public func updateNote(_ note: SyncedNote, body: String) async throws {
            guard let range = versesRange(note.verses) else {
                return
            }

            analytics.updateNote(verses: Set(note.verses))
            try await syncService.updateNote(
                localId: note.localId,
                body: body,
                startSura: Int32(range.start.sura.suraNumber),
                startAyah: Int32(range.start.ayah),
                endSura: Int32(range.end.sura.suraNumber),
                endAyah: Int32(range.end.ayah)
            )
        }

        public func removeNote(_ note: SyncedNote) async throws {
            try await syncService.removeNote(localId: note.localId)
        }

        public func textForVerses(_ verses: [AyahNumber]) async throws -> String {
            let verseTexts = try await textService.textForVerses(verses, translations: [])
            return verses.sorted()
                .compactMap { verse in
                    verseTexts[verse].map { $0.arabicText + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))" }
                }
                .joined(separator: " ")
        }

        // MARK: Internal

        static func notes(from notes: [Note_], quran: Quran) -> [SyncedNote] {
            notes.compactMap { note(from: $0, quran: quran) }
                .sorted { $0.modifiedDate > $1.modifiedDate }
        }

        static func note(from note: Note_, quran: Quran) -> SyncedNote? {
            guard let start = AyahNumber(quran: quran, sura: Int(note.startSura), ayah: Int(note.startAyah)),
                  let end = AyahNumber(quran: quran, sura: Int(note.endSura), ayah: Int(note.endAyah)),
                  start <= end
            else {
                return nil
            }

            return SyncedNote(
                localId: note.localId,
                body: note.body,
                verses: start.array(to: end),
                modifiedDate: note.lastUpdated
            )
        }

        // MARK: Private

        private let syncService: SyncService
        private let textService: QuranTextDataService
        private let analytics: AnalyticsLibrary

        private func versesRange(_ verses: [AyahNumber]) -> (start: AyahNumber, end: AyahNumber)? {
            let verses = verses.sorted()
            guard let start = verses.first, let end = verses.last else {
                return nil
            }
            return (start, end)
        }
    }
#endif
