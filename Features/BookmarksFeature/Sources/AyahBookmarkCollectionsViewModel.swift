#if QURAN_SYNC
//
//  AyahBookmarkCollectionsViewModel.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Combine
import QuranAnnotations
import QuranKit
import QuranTextKit
import SwiftUI
import VLogging

@MainActor
final class AyahBookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        collection: AyahBookmarkCollection,
        quranTextDataService: QuranTextDataService,
        navigateToPage: @escaping (Page) -> Void,
        collectionDeleted: @escaping () -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.collection = collection
        collectionID = collection.collection.id
        self.quranTextDataService = quranTextDataService
        self.navigateToPage = navigateToPage
        self.collectionDeleted = collectionDeleted
    }

    // MARK: Internal

    @Published private(set) var collection: AyahBookmarkCollection
    @Published private(set) var ayahTexts: [AyahNumber: String] = [:]
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var isPresentingRenameCollection = false
    @Published var pendingCollectionName = ""

    func start() async {
        do {
            let sequence = ayahBookmarkCollectionService.collectionsSequence()
            for try await collections in sequence {
                if let collection = collections.first(where: {
                    $0.collection.id == collectionID
                }) {
                    self.collection = collection
                    try await loadAyahTexts(for: collection)
                }
            }
        } catch {
            self.error = error
        }
    }

    func navigateTo(_ bookmark: AyahCollectionBookmark) {
        logger.info("Bookmarks: select collection bookmark at \(bookmark.ayah)")
        navigateToPage(bookmark.ayah.page)
    }

    func deleteBookmark(_ bookmark: AyahCollectionBookmark) async {
        do {
            try await ayahBookmarkCollectionService.removeBookmarkFromCollection(bookmark)
        } catch {
            self.error = error
        }
    }

    func presentRenameCollection() {
        guard collection.kind.canRename else {
            return
        }
        pendingCollectionName = collection.collection.name
        isPresentingRenameCollection = true
    }

    func renamePendingCollection() async {
        guard collection.kind.canRename else {
            return
        }
        let name = pendingCollectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return
        }

        do {
            try await ayahBookmarkCollectionService.renameCollection(
                id: collection.collection.id,
                to: name
            )
        } catch {
            self.error = error
        }
    }

    func deleteCollection() async {
        guard collection.kind.canDelete else {
            return
        }

        do {
            try await ayahBookmarkCollectionService.removeCollection(
                id: collection.collection.id
            )
            collectionDeleted()
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let quranTextDataService: QuranTextDataService
    private let collectionID: String
    private let navigateToPage: (Page) -> Void
    private let collectionDeleted: () -> Void

    private func loadAyahTexts(for collection: AyahBookmarkCollection?) async throws {
        guard let collection else {
            ayahTexts = [:]
            return
        }

        let ayahs = collection.bookmarks.map(\.ayah)
        guard Set(ayahTexts.keys) != Set(ayahs) else {
            return
        }
        ayahTexts = try await quranTextDataService
            .textForVerses(ayahs, translations: [])
            .mapValues(\.arabicText)
    }
}
#endif
