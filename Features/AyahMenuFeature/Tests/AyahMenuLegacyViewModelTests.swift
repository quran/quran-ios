#if !QURAN_SYNC
import Analytics
import AnnotationsService
import Combine
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit
import XCTest
@testable import AyahMenuFeature
@testable import NotePersistence

@MainActor
final class AyahMenuLegacyViewModelTests: XCTestCase {
    func test_updateHighlightPersistsSelectedColorAndDismissesMenu() async {
        let persistence = NotePersistenceSpy()
        let sut = makeSUT(persistence: persistence)
        let listener = ListenerSpy()
        sut.listener = listener

        await sut.updateHighlight(color: .blue)

        XCTAssertEqual(persistence.setNoteCall, .init(
            note: nil,
            verses: [
                VersePersistenceModel(ayah: 7, sura: 1),
                VersePersistenceModel(ayah: 1, sura: 2),
            ],
            color: HighlightColor.blue.rawValue
        ))
        XCTAssertTrue(listener.didDismiss)
    }

    private func makeSUT(persistence: NotePersistence) -> AyahMenuViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let verses = [
            AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 7)!,
            AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 1)!,
        ]
        return AyahMenuViewModel(deps: .init(
            sourceView: UIView(),
            pointInView: .zero,
            verses: verses,
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            notes: [],
            noteService: NoteService(persistence: persistence, analytics: NoopAnalytics())
        ))
    }
}

private final class NotePersistenceSpy: NotePersistence {
    struct SetNoteCall: Equatable {
        let note: String?
        let verses: [VersePersistenceModel]
        let color: Int
    }

    private(set) var setNoteCall: SetNoteCall?

    func notes() -> AnyPublisher<[NotePersistenceModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func setNote(
        _ note: String?,
        verses: [VersePersistenceModel],
        color: Int
    ) async throws -> NotePersistenceModel {
        setNoteCall = .init(note: note, verses: verses, color: color)
        return NotePersistenceModel(
            verses: Set(verses),
            modifiedDate: .distantPast,
            note: note,
            color: color
        )
    }

    func removeNotes(with verses: [VersePersistenceModel]) async throws -> [NotePersistenceModel] {
        []
    }
}

private struct NoopAnalytics: AnalyticsLibrary {
    func logEvent(_ name: String, value: String) {}
}

@MainActor
private final class ListenerSpy: AyahMenuListener {
    private(set) var didDismiss = false

    func dismissAyahMenu() {
        didDismiss = true
    }

    func playAudio(_ from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {}
    func shareText(_ lines: [String], in sourceView: UIView, at point: CGPoint) {}
    func showTranslation(_ verses: [AyahNumber]) {}
    func showNoteEditor(for verses: [AyahNumber]) async {}
    func deleteNotes(in verses: [AyahNumber]) async {}
}
#endif
