#if QURAN_SYNC
//
//  AyahBookmarkCollectionsViewModel.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Combine
import QuranAnnotations
import QuranKit
import SwiftUI
import VLogging

@MainActor
final class AyahBookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        collection: AyahBookmarkCollection,
        navigateToPage: @escaping (Page) -> Void,
        collectionDeleted: @escaping () -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.collection = collection
        collectionID = collection.collection.id
        self.navigateToPage = navigateToPage
        self.collectionDeleted = collectionDeleted
    }

    // MARK: Internal

    @Published private(set) var collection: AyahBookmarkCollection?
    @Published var editMode: EditMode = .inactive
    @Published var error: Error?
    @Published var isPresentingRenameCollection = false
    @Published var pendingCollectionName = ""

    func start() async {
        do {
            let sequence = ayahBookmarkCollectionService.collectionsSequence()
            for try await collections in sequence {
                collection = collections.first {
                    $0.collection.id == collectionID
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
        guard let collection, collection.kind.canRename else {
            return
        }
        pendingCollectionName = collection.collection.name
        isPresentingRenameCollection = true
    }

    func renamePendingCollection() async {
        guard let collection, collection.kind.canRename else {
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
        guard let collection, collection.kind.canDelete else {
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
    private let collectionID: String
    private let navigateToPage: (Page) -> Void
    private let collectionDeleted: () -> Void
}
#endif
