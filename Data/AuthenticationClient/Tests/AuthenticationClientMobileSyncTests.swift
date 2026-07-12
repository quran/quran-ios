#if QURAN_SYNC
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
            authService: database.authService,
            quranDataService: database.quranDataService
        )

        try await client.logout()

        let notes = database.quranDataService.notesSequence().makeAsyncIterator()
        let storedNotes = try await notes.next()
        XCTAssertTrue(storedNotes?.isEmpty == true)
    }
}
#endif
