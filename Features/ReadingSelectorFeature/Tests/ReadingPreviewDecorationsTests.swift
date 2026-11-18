import QuranKit
import XCTest
@testable import ReadingSelectorFeature

final class ReadingPreviewDecorationsTests: XCTestCase {
    func test_previewDrawsChromeOnlyForReadingsDrawingItAtRuntime() {
        for reading in Reading.allReadings {
            let decorations = reading.previewDecorations
            if reading.drawsAyahNumbersAndSuraHeaders {
                let page = reading.quran.pages.last!
                XCTAssertEqual(decorations.ayahNumbers.map(\.ayah), page.verses, "\(reading)")
                XCTAssertEqual(decorations.suraHeaders.count, page.suras.count, "\(reading)")
            } else {
                XCTAssertTrue(decorations.ayahNumbers.isEmpty, "\(reading)")
                XCTAssertTrue(decorations.suraHeaders.isEmpty, "\(reading)")
            }
        }
    }
}
