#if QURAN_SYNC
//
//  AyahBookmarkCollectionService.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

import Foundation
@preconcurrency import MobileSync
import QuranAnnotations
import QuranKit
import ReadingService
import Utilities

public struct AyahBookmarkCollectionService {
    // MARK: Lifecycle

    public init(
        quranDataService: QuranDataService,
        readingPreferences: ReadingPreferences = .shared
    ) {
        self.quranDataService = quranDataService
        self.readingPreferences = readingPreferences
    }

    // MARK: Public

    public func createCollection(named name: String) async throws {
        _ = try await quranDataService.createCollection(named: name)
    }

    public func addAyahBookmarkToCollection(collectionId: String, ayah: AyahNumber) async throws {
        _ = try await quranDataService.addAyahBookmarkToCollection(
            collectionId: collectionId,
            sura: Int32(ayah.sura.suraNumber),
            ayah: Int32(ayah.ayah)
        )
    }

    public func removeCollection(id: String) async throws {
        _ = try await quranDataService.removeCollection(id: id)
    }

    public func renameCollection(id: String, to name: String) async throws {
        _ = try await quranDataService.updateCollection(id: id, name: name)
    }

    public func removeBookmarkFromCollection(_ bookmark: AyahCollectionBookmark) async throws {
        try await quranDataService.removeAyahBookmarkFromCollection(
            collectionId: bookmark.collectionID,
            bookmarkId: bookmark.id
        )
    }

    public func addAyahs(_ ayahs: [AyahNumber], toCollectionWithID collectionID: String) async throws {
        let collections = try await loadStoredCollections()
        guard let collection = collections.first(where: { $0.id == collectionID }) else {
            return
        }

        try await addAyahsIfNeeded(ayahs, to: collection)
    }

    public func removeAyahs(_ ayahs: [AyahNumber], fromCollectionWithID collectionID: String) async throws {
        let collections = try await loadStoredCollections()
        guard let collection = collections.first(where: { $0.id == collectionID }) else {
            return
        }

        try await removeAyahs(ayahs, from: [collection])
    }

    public func collectionsSequence() -> AnyAsyncSequence<[AyahBookmarkCollection]> {
        let readingPreferences = readingPreferences
        let sequence = quranDataService.collectionsWithBookmarksSequence()
            .map { collections in
                Self.collections(from: collections, quran: readingPreferences.reading.quran)
            }
        return .init(sequence)
    }

    // MARK: Internal

    static func collections(from collections: [CollectionWithAyahBookmarks], quran: Quran) -> [AyahBookmarkCollection] {
        collections.compactMap { collection in
            guard collection.collection.isDefault || !collection.collection.isSystem else {
                return nil
            }
            return AyahBookmarkCollection(
                id: collection.collection.id,
                name: collection.collection.name,
                isDefault: collection.collection.isDefault,
                isSystem: collection.collection.isSystem,
                bookmarks: collection.bookmarks.compactMap { bookmark(for: $0, quran: quran) }
            )
        }
    }

    static func ayahsToAdd(_ ayahs: [AyahNumber], to collection: AyahBookmarkCollection) -> [AyahNumber] {
        let existingAyahs = Set(collection.bookmarks.map(\.ayah))
        var seenAyahs = Set<AyahNumber>()

        return ayahs.filter { ayah in
            guard !existingAyahs.contains(ayah), !seenAyahs.contains(ayah) else {
                return false
            }
            seenAyahs.insert(ayah)
            return true
        }
    }

    // MARK: Private

    private let quranDataService: QuranDataService
    private let readingPreferences: ReadingPreferences

    private func loadStoredCollections() async throws -> [AyahBookmarkCollection] {
        let iterator = quranDataService.collectionsWithBookmarksSequence().makeAsyncIterator()
        let collections = try await iterator.next() ?? []
        return Self.collections(from: collections, quran: readingPreferences.reading.quran)
    }

    private func addAyahsIfNeeded(
        _ ayahs: [AyahNumber],
        to collection: AyahBookmarkCollection
    ) async throws {
        for ayah in Self.ayahsToAdd(ayahs, to: collection) {
            try await addAyahBookmarkToCollection(
                collectionId: collection.id,
                ayah: ayah
            )
        }
    }

    private func removeAyahs(
        _ ayahs: [AyahNumber],
        from collections: [AyahBookmarkCollection]
    ) async throws {
        let ayahs = Set(ayahs)
        for collection in collections {
            for bookmark in collection.bookmarks where ayahs.contains(bookmark.ayah) {
                try await removeBookmarkFromCollection(bookmark)
            }
        }
    }

    private static func bookmark(for bookmark: CollectionAyahBookmark, quran: Quran) -> AyahCollectionBookmark? {
        guard let ayah = AyahNumber(
            quran: quran,
            sura: Int(bookmark.sura),
            ayah: Int(bookmark.ayah)
        ) else {
            return nil
        }

        return AyahCollectionBookmark(id: bookmark.bookmarkId, collectionID: bookmark.collectionId, ayah: ayah)
    }
}
#endif
