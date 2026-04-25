import AnnotationsService
import Crashing
import FeaturesSupport
import Foundation
import QuranKit
import ReadingService
import UIKit
import VLogging

@MainActor
final class HighlightsViewModel: ObservableObject {
    struct Item: Equatable, Identifiable {
        let collection: HighlightCollection
        let count: Int

        var id: HighlightCollection.ID { collection.id }
    }

    init(
        highlightCollectionsUpdates: @escaping () -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error>,
        makeColorController: @escaping (HighlightCollection) -> UIViewController
    ) {
        self.highlightCollectionsUpdates = highlightCollectionsUpdates
        self.makeColorController = makeColorController
        items = HighlightCollection.allCases.map { Item(collection: $0, count: 0) }
    }

    @Published var items: [Item]
    @Published var error: Error?

    weak var presenter: UIViewController?

    func start() async {
        guard !didStart else {
            return
        }

        didStart = true
        defer { didStart = false }

        do {
            for try await collections in highlightCollectionsUpdates() {
                items = HighlightCollection.allCases.map { collection in
                    Item(collection: collection, count: collection.count(in: collections))
                }
            }
        } catch is CancellationError {
        } catch {
            self.error = error
        }
    }

    func showDetails(_ item: Item) {
        logger.info("Highlights: show \(item.collection) highlights")
        presenter?.navigationController?.pushViewController(makeColorController(item.collection), animated: true)
    }

    private let highlightCollectionsUpdates: () -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error>
    private let makeColorController: (HighlightCollection) -> UIViewController
    private var didStart = false
}

@MainActor
final class HighlightsColorViewModel: ObservableObject {
    struct Item: Equatable, Identifiable {
        let ayah: AyahNumber
        let modifiedDate: Date
        let verseText: String

        var id: AyahNumber { ayah }
    }

    // MARK: Lifecycle

    init(
        collection: HighlightCollection,
        highlightCollectionsUpdates: @escaping () -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error>,
        noteService: NoteService,
        removeHighlight: @escaping (AyahNumber) async throws -> Void,
        navigateTo: @escaping (AyahNumber) -> Void
    ) {
        self.collection = collection
        self.highlightCollectionsUpdates = highlightCollectionsUpdates
        self.noteService = noteService
        self.removeHighlight = removeHighlight
        navigateToVerse = navigateTo
    }

    // MARK: Internal

    @Published var items: [Item] = []
    @Published var error: Error?

    let collection: HighlightCollection

    func start() async {
        guard !didStart else {
            return
        }

        didStart = true
        defer { didStart = false }

        do {
            for try await collections in highlightCollectionsUpdates() {
                let currentQuran = readingPreferences.reading.quran
                let bookmarks = collection.bookmarks(in: collections)
                items = await makeItems(from: bookmarks, quran: currentQuran)
            }
        } catch is CancellationError {
        } catch {
            self.error = error
        }
    }

    func navigateTo(_ item: Item) {
        logger.info("Highlights: navigate to \(item.ayah)")
        navigateToVerse(item.ayah)
    }

    func deleteItem(_ item: Item) async {
        logger.info("Highlights: delete \(item.ayah) from \(collection)")
        do {
            try await removeHighlight(item.ayah)
        } catch {
            self.error = error
        }
    }

    // MARK: Private

    private let highlightCollectionsUpdates: () -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error>
    private let noteService: NoteService
    private let removeHighlight: (AyahNumber) async throws -> Void
    private let navigateToVerse: (AyahNumber) -> Void
    private let readingPreferences = ReadingPreferences.shared
    private var didStart = false

    private func makeItems(
        from bookmarks: [HighlightBookmarkSnapshot],
        quran: Quran
    ) async -> [Item] {
        await withTaskGroup(of: Item.self) { group in
            for bookmark in bookmarks {
                group.addTask {
                    let ayah = AyahNumber(quran: quran, sura: bookmark.sura, ayah: bookmark.ayah)!
                    do {
                        let verseText = try await self.noteService.textForVerses([ayah])
                        return Item(ayah: ayah, modifiedDate: bookmark.modifiedDate, verseText: verseText)
                    } catch {
                        crasher.recordError(error, reason: "HighlightColorViewModel.textForVerses")
                        return Item(ayah: ayah, modifiedDate: bookmark.modifiedDate, verseText: ayah.localizedName)
                    }
                }
            }
            return await group.collect()
                .sorted { $0.modifiedDate > $1.modifiedDate }
        }
    }
}
