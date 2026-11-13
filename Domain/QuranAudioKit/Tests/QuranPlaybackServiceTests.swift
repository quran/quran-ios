import AVFoundation
import BatchDownloaderFake
import Combine
import Foundation
import QuranAudio
import QuranKit
import ReciterService
import ReciterServiceFake
import SystemDependenciesFake
import XCTest
@testable import BatchDownloader
@testable import Preferences
@testable import QueuePlayer
@testable import QuranAudioKit

@MainActor
final class QuranPlaybackServiceTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        let streaming = AudioPreferences.shared.streamingEnabled
        let recentReciters = ReciterPreferences.shared.recentReciterIds
        restorePreferences = {
            AudioPreferences.shared.streamingEnabled = streaming
            ReciterPreferences.shared.recentReciterIds = recentReciters
        }
        AudioPreferences.shared.streamingEnabled = true
        suiteName = "QuranPlaybackServiceTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        progress = ListeningProgressStore(preferences: Preferences(userDefaults: defaults))
        downloadContext = BatchDownloaderFake.makeContext()
        let (manager, _) = await downloadContext.makeDownloader()
        downloader = QuranAudioDownloader(baseURL: URL(string: "https://example.com")!, downloader: manager)
        let bundle = SystemBundleFake()
        bundle.arrays["reciters.plist"] = [Reciter.gappedReciter.toPlistDictionary()] as NSArray
        reciters = ReciterDataRetriever(bundle: bundle)
        queue = QueuePlayerFake()
        service = makeService(queue: queue)
    }

    override func tearDown() async throws {
        service.stop()
        service = nil
        queue = nil
        progress = nil
        downloader = nil
        downloadContext = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        restorePreferences()
        restorePreferences = nil
        try await super.tearDown()
    }

    func testStopRetainsTheActualPlayingVerseForRelaunch() async throws {
        let verses = Quran.hafsMadani1405.firstSura.verses
        try await play(from: verses[0], to: verses[4])
        reportPlaying(fileIndex: 2)

        service.stop()

        let reloaded = ListeningProgressStore(preferences: Preferences(userDefaults: defaults))
        XCTAssertEqual(reloaded.checkpoint?.ayah(in: .hafsMadani1405), verses[2])
        XCTAssertEqual(reloaded.checkpoint?.completed, false)
        XCTAssertNil(service.currentAyah)
        XCTAssertEqual(service.state, .stopped)
    }

    func testNaturalCompletionAdvancesToTheNextUnplayedVerse() async throws {
        let verses = Quran.hafsMadani1405.firstSura.verses
        try await play(from: verses[0], to: verses[3])
        reportPlaying(fileIndex: 3)

        queue.actions?.playbackEnded(.completed)

        XCTAssertEqual(progress.checkpoint?.ayah(in: .hafsMadani1405), verses[4])
        XCTAssertEqual(progress.checkpoint?.reciterID, Reciter.gappedReciter.id)
        XCTAssertEqual(progress.checkpoint?.completed, false)
        XCTAssertEqual(service.state, .stopped)
    }

    func testPlaybackFailureDoesNotAdvanceToTheRequestedEnd() async throws {
        let verses = Quran.hafsMadani1405.firstSura.verses
        try await play(from: verses[0], to: verses[4])
        reportPlaying(fileIndex: 1)

        queue.actions?.playbackFailed(URLError(.networkConnectionLost))

        XCTAssertEqual(progress.checkpoint?.ayah(in: .hafsMadani1405), verses[1])
        XCTAssertNotNil(service.error)
        XCTAssertEqual(service.state, .stopped)
    }

    func testRecreatedServiceUsesCheckpointInsteadOfBrowsingFallback() async throws {
        let quran = Quran.hafsMadani1405
        let saved = try XCTUnwrap(AyahNumber(quran: quran, sura: 2, ayah: 255))
        progress.checkpoint = ListeningCheckpoint(ayah: saved, reciterID: Reciter.gappedReciter.id)
        service = makeService(queue: queue)

        try await service.continueListening(quran: quran, fallback: quran.firstVerse, pageCount: 1)

        XCTAssertEqual(service.range?.start, saved)
        XCTAssertEqual(service.range?.end, saved.page.lastVerse)
        XCTAssertEqual(service.activeReciter?.id, Reciter.gappedReciter.id)
        XCTAssertEqual(progress.checkpoint?.ayah(in: quran), saved, "Preparing a range must not mark its endpoint as listened")
    }

    func testFinalVerseCompletionDoesNotWrapToTheBeginning() async throws {
        let quran = Quran.hafsMadani1405
        try await play(from: quran.lastVerse, to: quran.lastVerse)

        queue.actions?.playbackEnded(.completed)

        XCTAssertEqual(progress.checkpoint?.completed, true)
        do {
            try await service.continueListening(quran: quran, fallback: quran.firstVerse, pageCount: 5)
            XCTFail("A completed Quran should require choosing a new starting point")
        } catch QuranPlaybackError.quranCompleted {
            XCTAssertEqual(progress.checkpoint?.ayah(in: quran), quran.lastVerse)
        }
    }

    func testReadinessFailureLeavesExistingProgressUntouched() async throws {
        let quran = Quran.hafsMadani1405
        let checkpoint = ListeningCheckpoint(ayah: quran.pages[10].firstVerse, reciterID: Reciter.gappedReciter.id)
        progress.checkpoint = checkpoint
        queue.readinessError = URLError(.notConnectedToInternet)

        do {
            try await play(from: quran.firstVerse, to: quran.firstSura.lastVerse)
            XCTFail("Readiness failure must propagate to the caller")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        XCTAssertEqual(progress.checkpoint, checkpoint)
        XCTAssertEqual(service.state, .stopped)
        XCTAssertTrue(queue.state.isStopped)
    }

    func testCancelledRequestDoesNotStopExistingPlayback() async throws {
        let quran = Quran.hafsMadani1405
        let end = quran.firstSura.lastVerse
        try await play(from: quran.firstVerse, to: end)
        reportPlaying(fileIndex: 0)
        let service = service!

        let cancelled = Task { @MainActor in
            withUnsafeCurrentTask { $0?.cancel() }
            try await service.play(
                from: quran.lastVerse, to: quran.lastVerse,
                verseRuns: .finite(1), listRuns: .finite(1), rate: 1,
                verseDelay: .none, repetitionDelay: .none
            )
        }
        do {
            try await cancelled.value
            XCTFail("A cancelled request must fail before replacing playback")
        } catch is CancellationError {
            XCTAssertTrue(queue.state.isPlaying)
            XCTAssertEqual(service.state, .playing)
            XCTAssertEqual(service.range?.end, end)
        }
    }

    func testFrameReportedBeforeReadinessDoesNotOverwriteCheckpoint() async throws {
        let quran = Quran.hafsMadani1405
        let original = ListeningCheckpoint(ayah: quran.pages[10].firstVerse, reciterID: Reciter.gappedReciter.id)
        progress.checkpoint = original
        let pendingQueue = PendingReadinessQueuePlayer()
        let waiting = expectation(description: "Waiting for readiness")
        pendingQueue.onWaiting = { waiting.fulfill() }
        queue = pendingQueue
        service = makeService(queue: queue)
        let playTask = Task { try await self.play(from: quran.firstVerse, to: quran.firstSura.lastVerse) }
        await fulfillment(of: [waiting], timeout: 2)

        reportPlaying(fileIndex: 0)
        XCTAssertEqual(progress.checkpoint, original)
        pendingQueue.finishReadiness(.success(()))
        try await playTask.value

        XCTAssertEqual(progress.checkpoint?.ayah(in: quran), quran.firstVerse)
    }

    func testFailedReadinessAfterFrameCallbackKeepsEarlierCheckpoint() async throws {
        let quran = Quran.hafsMadani1405
        let original = ListeningCheckpoint(ayah: quran.pages[10].firstVerse, reciterID: Reciter.gappedReciter.id)
        progress.checkpoint = original
        let pendingQueue = PendingReadinessQueuePlayer()
        let waiting = expectation(description: "Waiting for readiness")
        pendingQueue.onWaiting = { waiting.fulfill() }
        queue = pendingQueue
        service = makeService(queue: queue)
        let playTask = Task { try await self.play(from: quran.firstVerse, to: quran.firstSura.lastVerse) }
        await fulfillment(of: [waiting], timeout: 2)

        reportPlaying(fileIndex: 0)
        pendingQueue.finishReadiness(.failure(URLError(.notConnectedToInternet)))
        do {
            try await playTask.value
            XCTFail("Readiness should fail")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }

        XCTAssertEqual(progress.checkpoint, original)
    }

    func testRemotePlayUsesReaderActionWhenStopped() async {
        var idlePlayCount = 0
        service.playWhenStopped = { idlePlayCount += 1 }
        await service.start()

        service.handleRemotePlay()

        XCTAssertEqual(idlePlayCount, 1)
        XCTAssertTrue(queue.state.isStopped)
    }

    func testRemotePlayResumesPausedRequestWithoutInvokingReaderAction() async throws {
        let quran = Quran.hafsMadani1405
        try await play(from: quran.firstVerse, to: quran.firstSura.lastVerse)
        service.pause()
        queue.actions?.playbackRateChanged(0)
        var idlePlayCount = 0
        service.playWhenStopped = { idlePlayCount += 1 }

        service.handleRemotePlay()

        XCTAssertEqual(idlePlayCount, 0)
        XCTAssertTrue(queue.state.isPlaying)
    }

    func testStartRestoresAggregateDownloadProgressWithoutAutoplay() async throws {
        let first = try await makeRunningDownload()
        let second = try await makeRunningDownload()
        await first.updateProgress(of: first.requests[0], DownloadProgress(total: 100, completed: 25))
        await second.updateProgress(of: second.requests[0], DownloadProgress(total: 100, completed: 75))

        await service.start()

        XCTAssertEqual(service.state, .downloading(progress: 0.5))
        XCTAssertTrue(queue.state.isStopped)
        XCTAssertNil(service.range)
        await first.complete(first.requests[0], result: .success(()))
        await second.complete(second.requests[0], result: .success(()))
        await waitForState(.stopped)
        XCTAssertTrue(queue.state.isStopped)
        XCTAssertNil(progress.checkpoint)
    }

    func testCancelDownloadCancelsEveryRestoredBatch() async throws {
        let downloads = [try await makeRunningDownload(), try await makeRunningDownload()]
        await service.start()

        await service.cancelDownload()

        for download in downloads {
            do {
                for try await _ in download.progress { }
                XCTFail("Restored batch should have been cancelled")
            } catch is CancellationError { }
        }
        XCTAssertEqual(service.state, .stopped)
    }

    func testRestoredDownloadCompletionDoesNotOverwriteNewPlayback() async throws {
        let restored = try await makeRunningDownload()
        await service.start()
        let initialGeneration = service.commandGeneration
        let quran = Quran.hafsMadani1405
        try await play(from: quran.firstVerse, to: quran.firstSura.lastVerse)
        reportPlaying(fileIndex: 0)
        XCTAssertGreaterThan(service.commandGeneration, initialGeneration)
        let overwritten = expectation(description: "Old download must not overwrite playback")
        overwritten.isInverted = true
        let subscription = service.$state.dropFirst().sink { state in
            if state != .playing { overwritten.fulfill() }
        }

        await restored.complete(restored.requests[0], result: .success(()))
        await fulfillment(of: [overwritten], timeout: 0.3)

        subscription.cancel()
        XCTAssertEqual(service.state, .playing)
        XCTAssertTrue(queue.state.isPlaying)
        let playingGeneration = service.commandGeneration
        service.stop()
        XCTAssertGreaterThan(service.commandGeneration, playingGeneration)
    }

    private var service: QuranPlaybackService!
    private var queue: QueuePlayerFake!
    private var progress: ListeningProgressStore!
    private var downloader: QuranAudioDownloader!
    private var reciters: ReciterDataRetriever!
    private var downloadContext: BatchDownloaderTestContext!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var restorePreferences: (() -> Void)!

    private func makeService(queue: QueuePlayerFake) -> QuranPlaybackService {
        QuranPlaybackService(
            downloader: downloader,
            player: QuranAudioPlayer(player: queue),
            progressStore: ListeningProgressStore(preferences: Preferences(userDefaults: defaults)),
            reciterRetriever: reciters
        )
    }

    private func play(from: AyahNumber, to: AyahNumber) async throws {
        try await service.play(
            from: from, to: to,
            reciterID: Reciter.gappedReciter.id,
            verseRuns: .finite(1), listRuns: .finite(1), rate: 1,
            verseDelay: .none, repetitionDelay: .none
        )
    }

    private func reportPlaying(fileIndex: Int) {
        let item = AVPlayerItem(url: URL(string: "https://example.com/recitation.mp3")!)
        queue.actions?.audioFrameChanged(fileIndex, 0, item, nil)
        queue.actions?.playbackRateChanged(1)
    }

    private func makeRunningDownload() async throws -> DownloadBatchResponse {
        let reciter = Reciter(
            id: 11,
            nameKey: "reciter1",
            directory: "playback-tests-\(UUID().uuidString)",
            audioURL: URL(string: "https://example.com/reciter")!,
            audioType: .gapped,
            hasGaplessAlternative: false,
            category: .arabic
        )
        let verse = Quran.hafsMadani1405.firstVerse
        return try await downloader.download(from: verse, to: verse, reciter: reciter)
    }

    private func waitForState(_ expected: QuranPlaybackState) async {
        let reached = expectation(description: "Playback state becomes \(expected)")
        reached.assertForOverFulfill = false
        let subscription = service.$state.sink { state in
            if state == expected { reached.fulfill() }
        }
        await fulfillment(of: [reached], timeout: 2)
        subscription.cancel()
    }
}

@MainActor
private final class PendingReadinessQueuePlayer: QueuePlayerFake {
    var onWaiting: (() -> Void)?

    override func waitUntilReady() async throws {
        try await withCheckedThrowingContinuation { continuation in
            readiness = continuation
            onWaiting?()
        }
    }

    func finishReadiness(_ result: Result<Void, Error>) {
        readiness?.resume(with: result)
        readiness = nil
    }

    private var readiness: CheckedContinuation<Void, Error>?
}
