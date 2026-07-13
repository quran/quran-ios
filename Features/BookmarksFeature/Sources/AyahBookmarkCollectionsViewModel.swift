#if QURAN_SYNC
//
//  AyahBookmarkCollectionsViewModel.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Combine
import QuranAnnotations
import QuranKit
import VLogging

@MainActor
final class AyahBookmarkCollectionsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        ayahBookmarkCollectionService: AyahBookmarkCollectionService,
        collectionID: String,
        navigateToPage: @escaping (Page) -> Void
    ) {
        self.ayahBookmarkCollectionService = ayahBookmarkCollectionService
        self.collectionID = collectionID
        self.navigateToPage = navigateToPage
    }

    // MARK: Internal

    @Published private(set) var collection: AyahBookmarkCollection?
    @Published var error: Error?

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

    // MARK: Private

    private let ayahBookmarkCollectionService: AyahBookmarkCollectionService
    private let collectionID: String
    private let navigateToPage: (Page) -> Void
}
#endif
