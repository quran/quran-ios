#if QURAN_SYNC
//
//  MobileSyncSwiftLogSinkTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-11.
//

import Logging
import MobileSync
import XCTest
@testable import SyncLogging

final class MobileSyncSwiftLogSinkTests: XCTestCase {
    func test_log_usesTagAsSourceAndMapsSeverity() {
        let handler = LogHandlerSpy()
        let sink = MobileSyncSwiftLogSink(logger: Logger(label: MobileSyncLogBridge.label) { _ in handler })

        sink.log(severity: .warn, tag: "NotesSyncAdapter", message: "Retrying sync")

        XCTAssertEqual(handler.entries, [.init(level: .warning, message: "Retrying sync", source: "NotesSyncAdapter")])
    }

    func test_minSeverity_mapsEveryLevel() {
        let levels: [Logger.Level] = [.trace, .debug, .info, .notice, .warning, .error, .critical]

        XCTAssertEqual(
            levels.map(MobileSyncLogBridge.minSeverity(for:)),
            [.verbose, .debug, .info, .warn, .warn, .error, .assert]
        )
    }
}

private final class LogHandlerSpy: LogHandler {
    struct Entry: Equatable {
        let level: Logger.Level
        let message: String
        let source: String
    }

    var entries: [Entry] = []
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .trace

    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        entries.append(Entry(level: level, message: message.description, source: source))
    }
}
#endif
