#if QURAN_SYNC
//
//  AyahBookmarkCollectionService.swift
//
//  Created by Ahmed Nabil on 2026-05-06.
//

import Foundation
import Localization
import MobileSync
import QuranAnnotations
import QuranKit
import ReadingService
import Utilities
import VLogging

public struct AyahBookmarkCollection {
    public let collection: Collection_
    public let bookmarks: [AyahCollectionBookmark]
}

public struct AyahCollectionBookmark {
    public let bookmark: CollectionAyahBookmark
    public let ayah: AyahNumber
}

private enum AyahBookmarkCollectionName {
    static let oldPageBookmarks = "Old Page Bookmarks"
}

private extension HighlightColor {
    init?(collectionName: String) {
        switch collectionName.lowercased() {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "yellow": self = .yellow
        case "purple": self = .purple
        default: return nil
        }
    }
}

public enum AyahBookmarkCollectionKind: Equatable {
    case defaultBookmarks
    case oldPageBookmarks
    case colored(HighlightColor)
    case user

    fileprivate init(collection: Collection_) {
        let normalizedName = collection.name.lowercased()
        if collection.isDefault {
            self = .defaultBookmarks
        } else if normalizedName == AyahBookmarkCollectionName.oldPageBookmarks.lowercased() {
            self = .oldPageBookmarks
        } else if let color = HighlightColor(collectionName: collection.name) {
            self = .colored(color)
        } else {
            self = .user
        }
    }

    var highlightColor: HighlightColor? {
        guard case .colored(let color) = self else {
            return nil
        }
        return color
    }

    var isOldPageBookmarks: Bool {
        self == .oldPageBookmarks
    }

    public var canDelete: Bool {
        highlightColor == nil && self != .defaultBookmarks
    }

    public var canRename: Bool {
        highlightColor == nil && self != .defaultBookmarks
    }
}

extension AyahBookmarkCollection {
    public var kind: AyahBookmarkCollectionKind {
        AyahBookmarkCollectionKind(collection: collection)
    }
}

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
        try await quranDataService.removeAyahBookmarkFromCollection(bookmark.bookmark)
    }

    public func setHighlight(_ color: HighlightColor?, for ayahs: [AyahNumber]) async throws {
        let collections = try await loadStoredCollections()
        let coloredCollections = collections.filter { $0.kind.highlightColor != nil }

        guard let color else {
            try await removeAyahs(ayahs, from: coloredCollections)
            return
        }

        guard let targetCollection = coloredCollections.first(where: { $0.kind == .colored(color) }) else {
            throw AyahBookmarkCollectionServiceError.highlightCollectionUnavailable
        }

        try await addAyahsIfNeeded(ayahs, to: targetCollection)
        try await removeAyahs(
            ayahs,
            from: coloredCollections.filter { $0.collection.id != targetCollection.collection.id }
        )
    }

    public func addAyahs(_ ayahs: [AyahNumber], toCollectionWithID collectionID: String) async throws {
        let collections = try await loadStoredCollections()
        guard let collection = collections.first(where: { $0.collection.id == collectionID }) else {
            return
        }

        try await addAyahsIfNeeded(ayahs, to: collection)
    }

    public func removeAyahs(_ ayahs: [AyahNumber], fromCollectionWithID collectionID: String) async throws {
        let collections = try await loadStoredCollections()
        guard let collection = collections.first(where: { $0.collection.id == collectionID }) else {
            return
        }

        try await removeAyahs(ayahs, from: [collection])
    }

    public func collectionsSequence() -> AnyAsyncSequence<[AyahBookmarkCollection]> {
        let quranDataService = quranDataService
        let readingPreferences = readingPreferences
        let sequence = quranDataService.collectionsWithBookmarksSequence()
            .map { collections in
                let collections = Self.collections(
                    from: collections,
                    quran: readingPreferences.reading.quran
                )
                await quranDataService.createHighlightCollectionsIfNeeded(collections)
                return collections
            }
        return .init(sequence)
    }

    // MARK: Internal

    static func collections(from collections: [CollectionWithAyahBookmarks], quran: Quran) -> [AyahBookmarkCollection] {
        collections.map { collection in
            AyahBookmarkCollection(
                collection: collection.collection,
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
                collectionId: collection.collection.id,
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

        return AyahCollectionBookmark(bookmark: bookmark, ayah: ayah)
    }
}

private enum AyahBookmarkCollectionServiceError: LocalizedError {
    case highlightCollectionUnavailable

    var errorDescription: String? {
        l("bookmarks.editor.error.highlight-unavailable")
    }
}

actor HighlightCollectionCreationPlanner {
    func reserveMissingCollectionNames(from collections: [AyahBookmarkCollection]) -> [String] {
        let existingNames = Set(collections.map(\.collection.name))
        reservedCollectionNames.formUnion(existingNames)

        let missingCollectionNames = HighlightColor.sortedColors
            .map(\.collectionName)
            .filter { !existingNames.contains($0) && !reservedCollectionNames.contains($0) }

        reservedCollectionNames.formUnion(missingCollectionNames)
        return missingCollectionNames
    }

    func releaseCollectionNames(_ names: some Sequence<String>) {
        reservedCollectionNames.subtract(names)
    }

    private var reservedCollectionNames: Set<String> = []
}

private extension QuranDataService {
    func createHighlightCollectionsIfNeeded(_ collections: [AyahBookmarkCollection]) async {
        let planner = await highlightCollectionCreationPlanners.planner(for: self)
        let missingCollectionNames = await planner.reserveMissingCollectionNames(from: collections)

        let failedCollections = await createHighlightCollections(named: missingCollectionNames)
        if !failedCollections.isEmpty {
            await planner.releaseCollectionNames(failedCollections)
        }
    }

    private func createHighlightCollections(named names: [String]) async -> [String] {
        await withTaskGroup(of: String?.self) { group in
            for name in names {
                group.addTask {
                    do {
                        _ = try await self.createCollection(named: name)
                        return nil
                    } catch {
                        logger.error("Bookmarks: failed to create highlight collection '\(name)': \(error)")
                        return name
                    }
                }
            }

            var failures: [String] = []
            for await name in group {
                if let name {
                    failures.append(name)
                }
            }

            return failures
        }
    }
}

private let highlightCollectionCreationPlanners = HighlightCollectionCreationPlanners()

private actor HighlightCollectionCreationPlanners {
    func planner(for quranDataService: QuranDataService) -> HighlightCollectionCreationPlanner {
        let id = ObjectIdentifier(quranDataService)
        let planner = planners[id] ?? HighlightCollectionCreationPlanner()
        planners[id] = planner
        return planner
    }

    private var planners: [ObjectIdentifier: HighlightCollectionCreationPlanner] = [:]
}

#endif
