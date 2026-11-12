#if QURAN_SYNC
import AnnotationsService
import AuthenticationClient
import AuthenticationClientFake
import Combine
import MobileSync
import MobileSyncTestSupport
import QuranAnnotations
import QuranKit
import QuranLocalization
import QuranResources
import QuranTextKit
import ReadingService
import UIKit
import XCTest
@testable import LegacyDataMigration
@testable import NotesFeature

@MainActor
final class NotesViewModelTests: XCTestCase {
    private let database = MobileSyncTestDatabase.shared
    private var noteService: MobileSyncNoteService!
    private var highlightService: MobileSyncAyahHighlightService!

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        LegacyImportPreferences.reset()
        NotesPreferences.reset()
        noteService = MobileSyncNoteService(quranDataService: database.quranDataService)
        highlightService = MobileSyncAyahHighlightService(quranDataService: database.quranDataService)
    }

    override func tearDown() async throws {
        try await database.reset()
        LegacyImportPreferences.reset()
        NotesPreferences.reset()
        noteService = nil
        highlightService = nil
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
            quranDataService: database.quranDataService,
            noteService: noteService,
            ayahHighlightService: highlightService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in },
            showHighlights: {}
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
            authenticationClient: UnavailableAuthenticationClient(),
            quranDataService: database.quranDataService,
            noteService: noteService,
            ayahHighlightService: highlightService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in },
            showHighlights: {}
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
        task.cancel()
    }

    func test_canRefresh_requiresSignIn_andStaysWhileEditing() {
        let sut = makeSUT()
        XCTAssertFalse(sut.canRefresh)

        sut.isAuthenticated = true
        XCTAssertTrue(sut.canRefresh)

        sut.editMode = .active
        XCTAssertTrue(sut.canRefresh)
    }

    func test_refresh_whileSignedOut_doesNotSync() async {
        let result = await makeSUT().refresh()

        XCTAssertNil(result)
    }

    func test_refresh_whenMobileSyncHasNoSession_returnsTheSyncsSignedOutResult() async {
        let sut = makeSUT()
        sut.isAuthenticated = true

        // MobileSync has no session here, so its sync ends at once.
        let result = await sut.refresh()

        XCTAssertEqual(result, .signedOut)
        XCTAssertNil(sut.error)
    }

    func test_signInAndSignOutElsewhere_showAndHidePullToRefresh() async throws {
        let client = AuthenticationClientFake()
        client.authenticationStateAfterLogin = .authenticated
        let sut = makeSUT(authenticationClient: client)

        try await client.login(on: UIViewController())
        await waitUntil { sut.canRefresh }

        try await client.logout()
        await waitUntil { !sut.canRefresh }
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
            authenticationClient: UnavailableAuthenticationClient(),
            quranDataService: database.quranDataService,
            noteService: noteService,
            ayahHighlightService: highlightService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: QuranResources.quranUthmaniV2Database
            ),
            navigateTo: { _ in },
            editNote: { _ in },
            showHighlights: {}
        )
        sut.notes = [NoteItem(note: note, quranText: "Verse")]
        QuranContentStatePreferences.shared.quranMode = .arabic

        let text = try await sut.prepareNotesForSharing()

        XCTAssertTrue(text.hasPrefix("My note\n\n"))
        XCTAssertTrue(text.contains("﴿ ١ ﴾"))
        XCTAssertTrue(text.hasSuffix("Al-Fātihah 1:1"))
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
            authenticationClient: UnavailableAuthenticationClient(),
            quranDataService: database.quranDataService,
            noteService: noteService,
            ayahHighlightService: highlightService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { navigatedAyah = $0 },
            editNote: { _ in },
            showHighlights: {}
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

    func test_highlightsTip_showsForUpgraderWithHighlights() async throws {
        LegacyImportPreferences.shared.hadHighlights = true
        try await highlightService.setHighlight(.yellow, for: [ayah(2, 255)])
        let sut = makeSUT()

        let task = Task { await sut.start() }
        defer { task.cancel() }

        await waitUntil { sut.showsHighlightsTip }
    }

    func test_highlightsTip_appearsWhenAnImportLaterRecordsLegacyHighlights() async throws {
        try await highlightService.setHighlight(.yellow, for: [ayah(2, 255)])
        let sut = makeSUT()
        let task = await start(sut, untilHighlightCount: 1)
        defer { task.cancel() }
        XCTAssertFalse(sut.showsHighlightsTip)

        LegacyImportPreferences.shared.hadHighlights = true

        await waitUntil { sut.showsHighlightsTip }
    }

    func test_dismissHighlightsTip_retiresItForLaterLaunches() async throws {
        LegacyImportPreferences.shared.hadHighlights = true
        try await highlightService.setHighlight(.yellow, for: [ayah(2, 255)])
        let sut = makeSUT()
        let task = await start(sut, untilHighlightCount: 1)
        defer { task.cancel() }

        sut.dismissHighlightsTip()

        XCTAssertFalse(sut.showsHighlightsTip)
        let relaunched = makeSUT()
        let relaunchedTask = await start(relaunched, untilHighlightCount: 1)
        defer { relaunchedTask.cancel() }
        XCTAssertFalse(relaunched.showsHighlightsTip)
    }

    func test_showHighlights_opensBookmarks_andRetiresTip() async throws {
        LegacyImportPreferences.shared.hadHighlights = true
        try await highlightService.setHighlight(.yellow, for: [ayah(2, 255)])
        var showedHighlights = false
        let sut = makeSUT(showHighlights: { showedHighlights = true })
        let task = await start(sut, untilHighlightCount: 1)
        defer { task.cancel() }

        sut.showHighlights()

        XCTAssertTrue(showedHighlights)
        XCTAssertFalse(sut.showsHighlightsTip)
    }

    func test_highlightsSummary_showsTheFourMostUsedColors() async throws {
        try await highlightService.setHighlight(.purple, for: (1 ... 5).map { ayah(2, $0) })
        try await highlightService.setHighlight(.pink, for: (6 ... 9).map { ayah(2, $0) })
        try await highlightService.setHighlight(.blue, for: (10 ... 12).map { ayah(2, $0) })
        try await highlightService.setHighlight(.green, for: (13 ... 14).map { ayah(2, $0) })
        try await highlightService.setHighlight(.yellow, for: [ayah(2, 15)])
        let sut = makeSUT()

        let task = await start(sut, untilHighlightCount: 15)
        defer { task.cancel() }

        XCTAssertEqual(sut.highlightsSummary, NotesHighlightsSummary(colors: [.purple, .pink, .blue, .green]))
    }

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: .hafsMadani1405, sura: sura, ayah: ayah)!
    }

    /// Starts observing and waits until the stored highlights arrive.
    private func start(_ sut: NotesViewModel, untilHighlightCount count: Int) async -> Task<Void, Never> {
        let task = Task { await sut.start() }
        await waitUntil { sut.highlights.count == count }
        return task
    }

    private func storedNotes() async throws -> [QuranAnnotations.Note] {
        var iterator = noteService.notesSequence(quran: .hafsMadani1405).makeAsyncIterator()
        return try await iterator.next() ?? []
    }

    private func makeSUT(
        authenticationClient: any AuthenticationClient = UnavailableAuthenticationClient(),
        showHighlights: @escaping () -> Void = {}
    ) -> NotesViewModel {
        let unavailableDatabase = URL(fileURLWithPath: "/tmp/unavailable-quran-database")
        return NotesViewModel(
            authenticationClient: authenticationClient,
            quranDataService: database.quranDataService,
            noteService: noteService,
            ayahHighlightService: highlightService,
            textService: QuranTextDataService(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            textRetriever: ShareableVerseTextRetriever(
                databasesURL: unavailableDatabase,
                quranFileURL: unavailableDatabase
            ),
            navigateTo: { _ in },
            editNote: { _ in },
            showHighlights: showHighlights
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

#endif
