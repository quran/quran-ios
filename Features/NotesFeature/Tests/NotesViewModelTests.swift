#if QURAN_SYNC
import Analytics
import AnalyticsFake
import AnnotationsService
import AuthenticationClient
import AuthenticationClientFake
import Combine
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranLocalization
import QuranResources
import QuranTextKit
import ReadingService
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
            analytics: AnalyticsLibrarySpy(),
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

        sut.notes = [item]
        let operation = try XCTUnwrap(sut.deleteItem(item))
        XCTAssertTrue(sut.notes.isEmpty)
        await operation()

        let notes = try await storedNotes()
        XCTAssertTrue(notes.isEmpty)
        XCTAssertNil(sut.error)
    }

    func test_start_observesNotesFromMobileSyncDatabase() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        try await noteService.createNote(body: "Observed note", startAyah: ayah, endAyah: ayah)
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        let sut = NotesViewModel(
            analytics: AnalyticsLibrarySpy(),
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

    func test_start_remapsNotes_whenReadingChanges() async throws {
        let readingPreferences = ReadingPreferences.shared
        let originalReading = readingPreferences.reading
        readingPreferences.reading = .hafs_1405
        defer { readingPreferences.reading = originalReading }
        let madaniAyah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let indoPakAyah = try XCTUnwrap(AyahNumber(quran: .hafsIndoPak, sura: 2, ayah: 255))
        try await noteService.createNote(body: "Observed note", startAyah: madaniAyah, endAyah: madaniAyah)
        let sut = makeSUT()
        let observedMadani = expectation(description: "Observes the note in the Madani Quran")
        let observedIndoPak = expectation(description: "Observes the note in the IndoPak Quran")
        observedMadani.assertForOverFulfill = false
        observedIndoPak.assertForOverFulfill = false
        let observation = sut.$notes.sink { notes in
            switch notes.map(\.note.startAyah) {
            case [madaniAyah]: observedMadani.fulfill()
            case [indoPakAyah]: observedIndoPak.fulfill()
            default: break
            }
        }
        let task = Task { await sut.start() }
        defer {
            task.cancel()
            observation.cancel()
        }
        await fulfillment(of: [observedMadani], timeout: 2)

        readingPreferences.reading = .indoPak

        await fulfillment(of: [observedIndoPak], timeout: 2)
        XCTAssertEqual(sut.notes.map(\.note.startAyah.quran), [.hafsIndoPak])
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
        client.authenticationStateValue = .authenticated
        let analytics = AnalyticsLibrarySpy()
        let sut = makeSUT(analytics: analytics, authenticationClient: client)

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login, .readAuthenticationState])
        XCTAssertEqual(analytics.events, [.init(name: "QuranSyncSignIn", value: "notes")])
        XCTAssertNil(sut.error)
    }

    func test_login_setsError_whenLoginFails() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.authenticationFailed(underlying: TestError.loginFailed))
        let sut = makeSUT(authenticationClient: client)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        guard case .authenticationFailed = sut.error as? AuthenticationClientError else {
            return XCTFail("Expected authenticationFailed, got \(String(describing: sut.error))")
        }
    }

    func test_login_ignoresCancellation() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.cancelled)
        let sut = makeSUT(authenticationClient: client)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_dismissSyncBanner_persistsDismissal() {
        let analytics = AnalyticsLibrarySpy()
        let sut = makeSUT(analytics: analytics)

        sut.dismissSyncBanner()

        XCTAssertTrue(sut.isSyncBannerDismissed)
        XCTAssertTrue(AuthenticationPreferences.shared.isNotesSyncBannerDismissed)
        XCTAssertFalse(sut.shouldShowSyncBanner)
        XCTAssertEqual(
            analytics.events,
            [.init(name: "QuranSyncSignInBannerDismissed", value: "notes")]
        )
    }

    func test_prepareNotesForSharing_usesShareableVerseText() async throws {
        let ayah = AyahNumber(quran: .hafsMadani1405, sura: 1, ayah: 1)!
        let note = QuranAnnotations.Note(
            id: "note",
            text: "My note",
            verses: [ayah],
            modifiedDate: Date()
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-translations-database")
        let sut = NotesViewModel(
            analytics: AnalyticsLibrarySpy(),
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
            verses: Set(startAyah.array(to: endAyah)),
            modifiedDate: .distantPast
        )
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        var navigatedAyah: AyahNumber?
        let sut = NotesViewModel(
            analytics: AnalyticsLibrarySpy(),
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

    func test_filteredNotes_matchesSuraOfAnyRange() {
        let quran = Quran.hafsMadani1405
        let note = QuranAnnotations.Note(
            id: "note",
            text: "On two passages",
            verses: [quran.suras[1].verses[254], quran.suras[2].verses[17]],
            modifiedDate: .distantPast
        )
        let sut = makeSUT()
        sut.notes = [NoteItem(note: note, quranText: nil)]

        sut.searchTerm = quran.suras[2].localizedName()

        XCTAssertEqual(sut.filteredNotes.map(\.id), ["note"])
    }

    private func storedNotes() async throws -> [QuranAnnotations.Note] {
        var iterator = noteService.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient()
    ) -> NotesViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        return NotesViewModel(
            analytics: analytics,
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
