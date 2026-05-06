#if QURAN_SYNC
    //
    //  OldPageBookmarksCollectionSync.swift
    //
    //  Created by Ahmed Nabil on 2026-05-06.
    //

    import AnnotationsService
    import Foundation
    import MobileSync
    import QuranAnnotations
    import QuranKit
    import ReadingService

    @MainActor
    struct OldPageBookmarksCollectionSync {
        // MARK: Lifecycle

        init(syncService: SyncService, pageBookmarkService: PageBookmarkService) {
            self.syncService = syncService
            self.pageBookmarkService = pageBookmarkService
        }

        // MARK: Internal

        static let collectionName = "Old Page Bookmarks"

        func sync() async throws {
            guard !Self.isSyncing else {
                return
            }
            Self.isSyncing = true
            defer {
                Self.isSyncing = false
            }

            let legacyBookmarks = await legacyPageBookmarksSnapshot()
            let collection = try await oldPageBookmarksCollection()
            var existingAyahs = Set(collection.bookmarks.map(AyahKey.init))

            for bookmark in legacyBookmarks {
                let ayah = bookmark.page.firstVerse
                let ayahKey = AyahKey(ayah)
                guard !existingAyahs.contains(ayahKey) else {
                    continue
                }
                _ = try await syncService.addAyahBookmarkToCollection(
                    collectionLocalId: collection.collection.localId,
                    sura: Int32(ayah.sura.suraNumber),
                    ayah: Int32(ayah.ayah)
                )
                existingAyahs.insert(ayahKey)
            }
        }

        // MARK: Private

        private static var isSyncing = false

        private let syncService: SyncService
        private let pageBookmarkService: PageBookmarkService
        private let readingPreferences = ReadingPreferences.shared

        private func oldPageBookmarksCollection() async throws -> CollectionWithAyahBookmarks {
            let collections = try await collectionsSnapshot()
            if let collection = collections.first(where: { $0.collection.name == Self.collectionName }) {
                return collection
            }

            try await syncService.createCollection(named: Self.collectionName)
            guard let collection = try await collectionsSnapshot()
                .first(where: { $0.collection.name == Self.collectionName })
            else {
                throw OldPageBookmarksCollectionSyncError.collectionUnavailable
            }
            return collection
        }

        private func collectionsSnapshot() async throws -> [CollectionWithAyahBookmarks] {
            var iterator = syncService.collectionsWithBookmarksSequence().makeAsyncIterator()
            return try await iterator.next() ?? []
        }

        private func legacyPageBookmarksSnapshot() async -> [PageBookmark] {
            var iterator = pageBookmarkService
                .pageBookmarks(quran: readingPreferences.reading.quran)
                .values()
                .makeAsyncIterator()
            return await iterator.next() ?? []
        }
    }

    private struct AyahKey: Hashable {
        // MARK: Lifecycle

        init(_ bookmark: CollectionAyahBookmark) {
            sura = bookmark.sura
            ayah = bookmark.ayah
        }

        init(_ ayahNumber: AyahNumber) {
            sura = Int32(ayahNumber.sura.suraNumber)
            ayah = Int32(ayahNumber.ayah)
        }

        // MARK: Internal

        let sura: Int32
        let ayah: Int32
    }

    private enum OldPageBookmarksCollectionSyncError: Error {
        case collectionUnavailable
    }
#endif
