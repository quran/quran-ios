import QuranKit
import XCTest
@testable import ReadingService

final class ReadingPreferencesTests: XCTestCase {
    func test_readings_startsWithTheReadingWhenIterationStarts() async {
        let preferences = ReadingPreferences.shared
        let originalReading = preferences.reading
        preferences.reading = .hafs_1405
        defer { preferences.reading = originalReading }
        let readings = preferences.readings()

        preferences.reading = .indoPak
        var iterator = readings.makeAsyncIterator()
        let first = await iterator.next()

        XCTAssertEqual(first, .indoPak)
    }
}
