import Foundation
import QuranKit
import XCTest
@testable import Preferences
@testable import QuranAudioKit

@MainActor
final class ListeningProgressStoreTests: XCTestCase {
    override func setUp() async throws {
        suiteName = "ListeningProgressStoreTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        preferences = Preferences(userDefaults: defaults)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: suiteName)
        preferences = nil
        defaults = nil
        suiteName = nil
    }

    func test_missingCheckpointIsNil() {
        XCTAssertNil(ListeningProgressStore(preferences: preferences).checkpoint)
    }

    func test_checkpointSurvivesRecreatingTheStore() throws {
        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let checkpoint = ListeningCheckpoint(ayah: ayah, reciterID: 7)
        ListeningProgressStore(preferences: preferences).checkpoint = checkpoint

        let reloaded = ListeningProgressStore(preferences: Preferences(userDefaults: defaults))
        XCTAssertEqual(reloaded.checkpoint, checkpoint)
    }

    func test_savedVerseMapsToTheCurrentLayout() throws {
        let original = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        let checkpoint = ListeningCheckpoint(ayah: original, reciterID: 7)
        let remapped = try XCTUnwrap(checkpoint.ayah(in: .hafsIndoPak))

        XCTAssertEqual(remapped.quran, .hafsIndoPak)
        XCTAssertEqual(remapped.sura.suraNumber, 2)
        XCTAssertEqual(remapped.ayah, 255)
    }

    func test_completionSurvivesReloading() {
        let checkpoint = ListeningCheckpoint(ayah: Quran.hafsMadani1405.lastVerse, reciterID: 7, completed: true)
        ListeningProgressStore(preferences: preferences).checkpoint = checkpoint

        XCTAssertEqual(ListeningProgressStore(preferences: preferences).checkpoint, checkpoint)
    }

    func test_clearingCheckpointRemovesStoredData() {
        let store = ListeningProgressStore(preferences: preferences)
        store.checkpoint = ListeningCheckpoint(ayah: Quran.hafsMadani1405.firstVerse, reciterID: 1)
        store.checkpoint = nil

        XCTAssertNil(store.checkpoint)
        XCTAssertNil(defaults.object(forKey: "listeningCheckpointV1"))
    }

    func test_corruptAndInvalidCheckpointsAreIgnored() {
        for payload in [
            "invalid json",
            "{\"sura\":2,\"verse\":999,\"reciterID\":1,\"completed\":false}",
            "{\"sura\":1,\"verse\":1,\"reciterID\":1,\"completed\":true}",
        ] {
            defaults.set(Data(payload.utf8), forKey: "listeningCheckpointV1")
            XCTAssertNil(ListeningProgressStore(preferences: preferences).checkpoint)
        }
    }

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var preferences: Preferences!
}
