import Analytics
import Combine
import FeaturesSupport
import Foundation
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit
import XCTest
@testable import AnnotationsService
@testable import BookmarksFeature
@testable import NotePersistence

@MainActor
final class HighlightsViewModelTests: XCTestCase {
    // MARK: Internal

    func test_start_refreshesWhenStartedAgain_afterPreviousTaskIsCancelled() async {
        let updates = HighlightCollectionsUpdatesSpy()
        let sut = HighlightsViewModel(
            highlightCollectionsUpdates: updates.updates,
            makeColorController: { _ in UIViewController() }
        )

        let startTask = Task { await sut.start() }
        await Task.yield()
        startTask.cancel()
        _ = await startTask.value

        updates.send([
            HighlightCollectionSnapshot(
                name: "blue",
                bookmarks: [HighlightBookmarkSnapshot(sura: 1, ayah: 1, modifiedDate: Date())]
            ),
        ])

        let restartedTask = Task { await sut.start() }
        await waitUntil { sut.items.first(where: { $0.collection == .blue })?.count == 1 }
        restartedTask.cancel()
    }

    func test_colorStart_refreshesWhenStartedAgain_afterPreviousTaskIsCancelled() async {
        let updates = HighlightCollectionsUpdatesSpy()
        let sut = HighlightsColorViewModel(
            collection: .blue,
            highlightCollectionsUpdates: updates.updates,
            noteService: makeNoteService(),
            removeHighlight: { _ in },
            navigateTo: { _ in }
        )

        let startTask = Task { await sut.start() }
        await Task.yield()
        startTask.cancel()
        _ = await startTask.value

        updates.send([
            HighlightCollectionSnapshot(
                name: "blue",
                bookmarks: [HighlightBookmarkSnapshot(sura: 1, ayah: 1, modifiedDate: Date())]
            ),
        ])

        let restartedTask = Task { await sut.start() }
        await waitUntil(timeoutIterations: 1000) { sut.items.count == 1 }
        restartedTask.cancel()
    }

    func test_deleteItem_removesHighlightForSelectedAyah() async {
        let updates = HighlightCollectionsUpdatesSpy()
        let remover = HighlightRemoverSpy()
        let sut = HighlightsColorViewModel(
            collection: .blue,
            highlightCollectionsUpdates: updates.updates,
            noteService: makeNoteService(),
            removeHighlight: remover.removeHighlight,
            navigateTo: { _ in }
        )
        let item = HighlightsColorViewModel.Item(
            ayah: AyahNumber(quran: .hafs_1421, sura: 1, ayah: 1)!,
            modifiedDate: Date(),
            verseText: "text"
        )

        await sut.deleteItem(item)

        XCTAssertEqual(remover.removedAyahs, [item.ayah])
        XCTAssertNil(sut.error)
    }

    // MARK: Private

    private func makeNoteService() -> NoteService {
        let quranFileURL = repositoryRoot()
            .appendingPathComponent("Domain/QuranResources/Databases/quran.ar.uthmani.v2.db")
        return NoteService(
            persistence: NotePersistenceSpy(),
            textService: QuranTextDataService(
                databasesURL: quranFileURL.deletingLastPathComponent(),
                quranFileURL: quranFileURL
            ),
            analytics: AnalyticsSpy()
        )
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func waitUntil(
        timeoutIterations: Int = 100,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private final class HighlightCollectionsUpdatesSpy {
    private var currentCollections: [HighlightCollectionSnapshot] = []
    private var continuation: AsyncThrowingStream<[HighlightCollectionSnapshot], Error>.Continuation?

    func updates() -> AsyncThrowingStream<[HighlightCollectionSnapshot], Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.yield(self.currentCollections)
        }
    }

    func send(_ collections: [HighlightCollectionSnapshot]) {
        currentCollections = collections
        continuation?.yield(collections)
    }
}

private final class HighlightRemoverSpy {
    private(set) var removedAyahs: [AyahNumber] = []

    func removeHighlight(_ ayah: AyahNumber) async throws {
        removedAyahs.append(ayah)
    }
}

private struct AnalyticsSpy: AnalyticsLibrary {
    func logEvent(_: String, value _: String) {}
}

private final class NotePersistenceSpy: NotePersistence {
    func notes() -> AnyPublisher<[NotePersistenceModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func setNote(_: String?, verses _: [VersePersistenceModel], color _: Int) async throws -> NotePersistenceModel {
        NotePersistenceModel(nil, color: 0, modifiedDate: Date())
    }

    func removeNotes(with _: [VersePersistenceModel]) async throws -> [NotePersistenceModel] {
        []
    }
}

private extension NotePersistenceModel {
    init(_ text: String?, color: Int, modifiedDate: Date, verses: Set<VersePersistenceModel> = []) {
        self.init(verses: verses, modifiedDate: modifiedDate, note: text, color: color)
    }
}
