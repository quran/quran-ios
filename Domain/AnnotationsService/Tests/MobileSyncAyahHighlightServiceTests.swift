#if QURAN_SYNC
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import XCTest
@testable import AnnotationsService

final class MobileSyncAyahHighlightServiceTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var service: MobileSyncAyahHighlightService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        service = MobileSyncAyahHighlightService(
            quranDataService: database.quranDataService,
            quran: .hafsMadani1405
        )
    }

    override func tearDown() async throws {
        try await database.reset()
        service = nil
        try await super.tearDown()
    }

    func test_setHighlight_replacesExistingHighlights() async throws {
        try await service.setHighlight(.red, for: [ayah(1), ayah(2)])
        try await service.setHighlight(.green, for: [ayah(1), ayah(2)])

        let highlights = try await storedHighlights(where: { $0.count == 2 })
        XCTAssertEqual(highlights[ayah(1)], .green)
        XCTAssertEqual(highlights[ayah(2)], .green)
    }

    func test_removeHighlight_removesExistingHighlights() async throws {
        try await service.setHighlight(.red, for: [ayah(1), ayah(2)])

        try await service.removeHighlight(for: [ayah(1), ayah(2)])

        let highlights = try await storedHighlights(where: { $0.isEmpty })
        XCTAssertTrue(highlights.isEmpty)
    }

    func test_setHighlight_roundTripsEverySupportedColor() async throws {
        for color in HighlightColor.sortedColors {
            try await service.setHighlight(color, for: [ayah(1)])

            let highlights = try await storedHighlights(where: { $0[ayah(1)] == color })
            XCTAssertEqual(highlights[ayah(1)], color)
        }
    }

    private func storedHighlights(
        where predicate: ([AyahNumber: HighlightColor]) -> Bool
    ) async throws -> [AyahNumber: HighlightColor] {
        var iterator = service.highlightsSequence().makeAsyncIterator()
        while let highlights = try await iterator.next() {
            if predicate(highlights) {
                return highlights
            }
        }
        throw HighlightTestError.expectedDatabaseStateNotObserved
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}

private enum HighlightTestError: Error {
    case expectedDatabaseStateNotObserved
}
#endif
