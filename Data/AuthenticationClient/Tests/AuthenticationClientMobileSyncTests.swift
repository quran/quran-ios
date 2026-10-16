#if QURAN_SYNC
import Logging
import MobileSync
import MobileSyncTestSupport
import XCTest
@testable import AuthenticationClient

final class AuthenticationClientMobileSyncTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_logout_clearsMobileSyncDatabase() async throws {
        try await database.quranDataService.createNote(
            body: "Stored note",
            startSura: 1,
            startAyah: 1,
            endSura: 1,
            endAyah: 1
        )
        let client = AuthenticationClientMobileSyncImpl(
            authService: database.authService
        )

        try await client.logout()

        let notes = database.quranDataService.notesSequence().makeAsyncIterator()
        let storedNotes = try await notes.next()
        XCTAssertTrue(storedNotes?.isEmpty == true)
    }

    func test_logLoginFailure_logsCancellationAtInfo() {
        let handler = LogHandlerSpy()

        AuthenticationClientMobileSyncImpl.logLoginFailure(.cancelled, to: Logger(label: "test") { _ in handler })

        XCTAssertEqual(handler.entries, [.init(level: .info, message: "Login via mobile sync cancelled")])
    }

    func test_logLoginFailure_logsOtherFailuresAtError() {
        let handler = LogHandlerSpy()
        let error = MobileSyncAuthenticationError.authenticationFailed(underlying: URLError(.badServerResponse))

        AuthenticationClientMobileSyncImpl.logLoginFailure(error, to: Logger(label: "test") { _ in handler })

        XCTAssertEqual(handler.entries, [.init(level: .error, message: "Failed to login via mobile sync: \(error)")])
    }
}

private final class LogHandlerSpy: LogHandler {
    struct Entry: Equatable {
        let level: Logger.Level
        let message: String
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
        entries.append(Entry(level: level, message: message.description))
    }
}
#endif
