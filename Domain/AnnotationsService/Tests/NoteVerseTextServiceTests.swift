import QuranKit
import XCTest
@testable import AnnotationsService

final class NoteVerseTextServiceTests: XCTestCase {
    func test_textForVerses_sortsAndFormatsArabicText() async throws {
        let first = ayah(1)
        let second = ayah(2)
        let sut = NoteVerseTextService { _ in
            [
                second: "Second",
                first: "First",
            ]
        }

        let text = try await sut.textForVerses([second, first])

        XCTAssertEqual(text, "First ١ Second ٢")
    }

    func test_textForVerses_omitsUnavailableArabicText() async throws {
        let available = ayah(1)
        let sut = NoteVerseTextService { _ in [available: "Available"] }

        let text = try await sut.textForVerses([ayah(2), available])

        XCTAssertEqual(text, "Available ١")
    }

    func test_textForVerses_propagatesRetrievalError() async {
        let sut = NoteVerseTextService { _ in throw TestError.expected }

        do {
            _ = try await sut.textForVerses([ayah(1)])
            XCTFail("Expected text retrieval to throw")
        } catch {
            XCTAssertEqual(error as? TestError, .expected)
        }
    }

    private func ayah(_ number: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: number)!
    }
}

private enum TestError: Error, Equatable {
    case expected
}
