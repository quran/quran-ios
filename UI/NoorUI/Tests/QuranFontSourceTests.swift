import Combine
import XCTest
@testable import NoorUI

final class QuranFontSourceTests: XCTestCase {
    func test_current_readsLatestValue() {
        var current = QuranFont.uthmanicHafs
        let source = QuranFontSource(
            current: { current },
            updates: Empty<QuranFont, Never>()
        )

        current = .indoPak

        XCTAssertEqual(source.current, .indoPak)
    }

    func test_updates_emitsOnlyFontChangesAfterCurrentValue() {
        let updates = PassthroughSubject<QuranFont, Never>()
        let source = QuranFontSource(current: { .uthmanicHafs }, updates: updates)
        var received: [QuranFont] = []
        let cancellable = source.updates.sink { received.append($0) }

        updates.send(.uthmanicHafs)
        updates.send(.indoPak)
        updates.send(.indoPak)
        updates.send(.uthmanicHafs)

        XCTAssertEqual(source.current, .uthmanicHafs)
        XCTAssertEqual(received, [.indoPak, .uthmanicHafs])
        withExtendedLifetime(cancellable) {}
    }
}
