#if QURAN_SYNC
import AnnotationsService
import AuthenticationClient
import AuthenticationClientFake
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranResources
import QuranTextKit
import UIKit
import XCTest
@testable import NotesFeature

@MainActor
final class NotesViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var navigationController: UINavigationController!
    private var noteService: MobileSyncNoteService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        AuthenticationPreferences.shared.isNotesSyncBannerDismissed = false
        navigationController = UINavigationController()
        noteService = MobileSyncNoteService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        AuthenticationPreferences.shared.isNotesSyncBannerDismissed = false
        navigationController = nil
        noteService = nil
        try await super.tearDown()
    }

    func test_deleteItem_removesNoteFromMobileSyncDatabase() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        try await noteService.createNote(body: "Delete me", startAyah: ayah, endAyah: ayah)
        let stored = try await storedNotes()
        let note = try XCTUnwrap(stored.first)
        let item = NoteItem(note: note, quranText: "Verse")
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = NotesViewModel(
            authenticationClient: UnavailableAuthenticationClient(),
            navigationController: UINavigationController(),
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )

        await sut.deleteItem(item)

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_start_observesNotesFromMobileSyncDatabase() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        try await noteService.createNote(body: "Observed note", startAyah: ayah, endAyah: ayah)
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = NotesViewModel(
            authenticationClient: UnavailableAuthenticationClient(),
            navigationController: UINavigationController(),
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )
        let observed = expectation(description: "Observes persisted note")
        let observation = sut.$notes.sink { notes in
            if notes.map(\.noteText) == ["Observed note"] {
                observed.fulfill()
            }
        }

        let task = Task { await sut.start() }
        await fulfillment(of: [observed], timeout: 2)

        XCTAssertNil(sut.notes.first?.quranText)
        XCTAssertNil(sut.error)
        task.cancel()
        observation.cancel()
    }

    func test_start_setsAuthenticatedState_whenRestoreSucceeds() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        let sut = makeSUT(authenticationClient: client)

        let task = Task { await sut.start() }
        await waitUntil { sut.isAuthenticated }

        XCTAssertEqual(client.events.first, .restoreState)
        XCTAssertFalse(sut.shouldShowSyncBanner)
        task.cancel()
    }

    func test_login_setsAuthenticated_whenLoginSucceeds() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_login_setsError_whenLoginFails() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.clientIsNotAuthenticated(TestError.loginFailed))
        let sut = makeSUT(authenticationClient: client)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .clientIsNotAuthenticated = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected clientIsNotAuthenticated, got \(String(describing: sut.error))")
        }
    }

    func test_dismissSyncBanner_persistsDismissal() {
        let sut = makeSUT()

        sut.dismissSyncBanner()

        XCTAssertTrue(sut.isSyncBannerDismissed)
        XCTAssertTrue(AuthenticationPreferences.shared.isNotesSyncBannerDismissed)
        XCTAssertFalse(sut.shouldShowSyncBanner)
    }

    func test_prepareNotesForSharing_usesShareableVerseText() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        let note = QuranAnnotations.Note(
            id: "note",
            text: "My note",
            startAyah: ayah,
            endAyah: ayah,
            modifiedDate: Date()
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-translations-database")
        let sut = NotesViewModel(
            authenticationClient: UnavailableAuthenticationClient(),
            navigationController: UINavigationController(),
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )
        sut.notes = [NoteItem(note: note, quranText: "Verse")]
        QuranContentStatePreferences.shared.quranMode = .arabic

        let text = try await sut.prepareNotesForSharing()

        XCTAssertTrue(text.hasPrefix("My note\n\n"))
        XCTAssertTrue(text.contains("﴿ ١ ﴾"))
        XCTAssertTrue(text.hasSuffix("Al-Fātihah, Ayah 1"))
    }

    func test_navigateToNote_navigatesToStartAyah() throws {
        let startAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let endAyah = try XCTUnwrap(startAyah.next)
        let note = QuranAnnotations.Note(
            id: "note",
            text: "Ayat al-Kursi",
            startAyah: startAyah,
            endAyah: endAyah,
            modifiedDate: .distantPast
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        var navigatedAyah: AyahNumber?
        let sut = NotesViewModel(
            authenticationClient: UnavailableAuthenticationClient(),
            navigationController: UINavigationController(),
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { navigatedAyah = $0 },
            editNote: { _ in }
        )

        sut.navigateTo(NoteItem(note: note, quranText: nil))

        XCTAssertEqual(navigatedAyah, startAyah)
    }

    private func storedNotes() async throws -> [QuranAnnotations.Note] {
        var iterator = noteService.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func makeSUT(
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient()
    ) -> NotesViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        return NotesViewModel(
            authenticationClient: authenticationClient,
            navigationController: navigationController,
            noteService: noteService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in }
        )
    }

    private func waitUntil(
        timeoutIterations: Int = 1000,
        condition: @escaping @MainActor () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        for _ in 0 ..< timeoutIterations {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Condition was not met in time", file: file, line: line)
    }
}

private enum TestError: Error {
    case loginFailed
}
#endif
