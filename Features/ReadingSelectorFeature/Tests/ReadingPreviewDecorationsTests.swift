import NoorUI
import QuranGeometry
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

    func test_linePagePreviewChromeIsSizedLikeTheReaderAndFitsTheSample() throws {
        for reading in [Reading.hafs_1439, .hafs_1441] {
            let width = CGFloat(try XCTUnwrap(reading.linePageMetrics).widthParameter)
            let sample = CGRect(x: 0, y: 0, width: width, height: width * 1.6)
            let decorations = reading.previewDecorations

            XCTAssertEqual(decorations.ayahNumberWidthRatio, LinePageGeometryEngine.ayahMarkerWidthRatio)
            for header in decorations.suraHeaders {
                XCTAssertTrue(sample.contains(header.rect), "\(reading) \(header.rect)")
                XCTAssertEqual(header.rect.midX, sample.midX, accuracy: 1, "\(reading)")
            }

            let markerLength = decorations.ayahNumberWidthRatio * width
            for marker in decorations.ayahNumbers {
                let frame = CGRect(
                    x: marker.center.x - markerLength / 2,
                    y: marker.center.y - markerLength / 2,
                    width: markerLength,
                    height: markerLength
                )
                XCTAssertTrue(sample.contains(frame), "\(reading) \(marker.ayah)")
                XCTAssertFalse(decorations.suraHeaders.contains { $0.rect.intersects(frame) }, "\(reading) \(marker.ayah)")
            }
        }
    }
}
