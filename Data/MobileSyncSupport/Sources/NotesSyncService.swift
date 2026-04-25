//
//  NotesSyncService.swift
//
//
//  Created by Ahmed Nabil on 2026-04-22.
//

#if QURAN_SYNC
    import Foundation
    import MobileSync
    import QuranKit

    public struct NotesSyncService {
        // MARK: Lifecycle

        public init(syncService: SyncService) {
            self.syncService = syncService
        }

        // MARK: Public

        public func createNote(body: String, verses: Set<AyahNumber>) async throws {
            guard let range = Self.ayahIdRange(for: verses) else {
                return
            }
            try await syncService.createNote(body: body, startAyahId: range.start, endAyahId: range.end)
        }

        public func updateNote(localId: String, body: String, verses: Set<AyahNumber>) async throws {
            guard let range = Self.ayahIdRange(for: verses) else {
                return
            }
            try await syncService.updateNote(
                localId: localId,
                body: body,
                startAyahId: range.start,
                endAyahId: range.end
            )
        }

        public func removeNote(localId: String) async throws {
            try await syncService.removeNote(localId: localId)
        }

        public func snapshot() async throws -> [Note_] {
            for try await notes in syncService.notesSequence() {
                return notes
            }
            return []
        }

        // MARK: Private

        private let syncService: SyncService

        private static func ayahIdRange(for verses: Set<AyahNumber>) -> (start: Int64, end: Int64)? {
            guard let startVerse = verses.min(), let endVerse = verses.max() else {
                return nil
            }
            return (start: ayahId(for: startVerse), end: ayahId(for: endVerse))
        }

        private static func ayahId(for verse: AyahNumber) -> Int64 {
            Int64(QuranData.shared.getAyahId(sura: Int32(verse.sura.suraNumber), ayah: Int32(verse.ayah)))
        }
    }

#endif
