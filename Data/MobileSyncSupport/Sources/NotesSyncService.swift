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

        public func createNote(body: String, startVerse: AyahNumber, endVerse: AyahNumber) async throws {
            let range = Self.ayahIdRange(startVerse: startVerse, endVerse: endVerse)

            do {
                try await syncService.createNote(body: body, startAyahId: range.start, endAyahId: range.end)
            } catch {
                guard Self.isExpectedNoteAfterInsert(error),
                      try await noteExists(body: body, range: range)
                else {
                    throw error
                }
            }
        }

        public func updateNote(localId: String, body: String, startVerse: AyahNumber, endVerse: AyahNumber) async throws {
            let range = Self.ayahIdRange(startVerse: startVerse, endVerse: endVerse)
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

        private static func ayahIdRange(startVerse: AyahNumber, endVerse: AyahNumber) -> (start: Int64, end: Int64) {
            (start: ayahId(for: startVerse), end: ayahId(for: endVerse))
        }

        private static func ayahId(for verse: AyahNumber) -> Int64 {
            Int64(QuranData.shared.getAyahId(sura: Int32(verse.sura.suraNumber), ayah: Int32(verse.ayah)))
        }

        // TODO: Remove/Revisit this workaround once Mobile Sync stops throwing
        // "Expected note after insert." for notes that were actually persisted.
        // Today note creation can succeed in the sync store but still surface that
        // false-negative error, so we verify the inserted note exists before failing.
        private static func isExpectedNoteAfterInsert(_ error: Error) -> Bool {
            let description = String(describing: error)
            return description.contains("Expected note after insert.")
        }

        private func noteExists(body: String, range: (start: Int64, end: Int64)) async throws -> Bool {
            for attempt in 0 ..< 3 {
                let notes = try await snapshot()
                if notes.contains(where: {
                    $0.body == body && $0.startAyahId == range.start && $0.endAyahId == range.end
                }) {
                    return true
                }
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            return false
        }
    }

#endif
