#if !QURAN_SYNC
import Analytics
import Combine
import QuranKit
import XCTest
@testable import AnnotationsService
@testable import NotePersistence
@testable import QuranAnnotations

final class NoteServiceTests: XCTestCase {
    func test_notesIgnoresIncompleteAndInvalidPersistenceModels() {
        let persistence = NotePersistenceFake(notes: [
            NotePersistenceModel(
                verses: [],
                modifiedDate: .distantPast,
                note: "Incomplete",
                color: 0
            ),
            NotePersistenceModel(
                verses: [VersePersistenceModel(ayah: 999, sura: 1)],
                modifiedDate: .distantPast,
                note: "Invalid",
                color: 0
            ),
            NotePersistenceModel(
                verses: [VersePersistenceModel(ayah: 1, sura: 1)],
                modifiedDate: .distantPast,
                note: "Valid",
                color: 0
            ),
        ])
        let sut = NoteService(persistence: persistence, analytics: NoopAnalytics())

        var receivedNotes: [Note] = []
        let cancellable = sut.notes(quran: Quran.hafsMadani1405).sink { receivedNotes = $0 }
        withExtendedLifetime(cancellable) {}

        XCTAssertEqual(receivedNotes.count, 1)
        XCTAssertEqual(receivedNotes.first?.text, "Valid")
    }
}

private final class NotePersistenceFake: NotePersistence {
    init(notes: [NotePersistenceModel]) {
        models = notes
    }

    func notes() -> AnyPublisher<[NotePersistenceModel], Never> {
        Just(models).eraseToAnyPublisher()
    }

    func setNote(
        _ note: String?,
        verses: [VersePersistenceModel],
        color: Int
    ) async throws -> NotePersistenceModel {
        fatalError("Unavailable")
    }

    func removeNotes(with verses: [VersePersistenceModel]) async throws -> [NotePersistenceModel] {
        fatalError("Unavailable")
    }

    private let models: [NotePersistenceModel]
}

private struct NoopAnalytics: AnalyticsLibrary {
    func logEvent(_ name: String, value: String) {}
}
#endif
