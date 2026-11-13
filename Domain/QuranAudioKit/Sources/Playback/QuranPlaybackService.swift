import AVFoundation
import BatchDownloader
import Combine
import Foundation
import QueuePlayer
import QuranAudio
import QuranKit
import ReciterService

public enum QuranPlaybackState: Equatable {
    case stopped
    case downloading(progress: Double)
    case playing
    case paused
}

/// One app-owned playback session, shared by reader screens, Siri, and remote controls.
@MainActor
public final class QuranPlaybackService: ObservableObject {
    public typealias AudioRange = (start: AyahNumber, end: AyahNumber)

    public init(
        downloader: QuranAudioDownloader,
        player: QuranAudioPlayer? = nil,
        progressStore: ListeningProgressStore? = nil,
        reciterRetriever: ReciterDataRetriever = ReciterDataRetriever()
    ) {
        self.downloader = downloader
        let player = player ?? QuranAudioPlayer()
        self.player = player
        self.progressStore = progressStore ?? ListeningProgressStore()
        self.reciterRetriever = reciterRetriever
        player.setActions(QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.playbackEnded(reason: $0) },
            playbackPaused: { [weak self] in self?.state = .paused },
            playbackResumed: { [weak self] in self?.state = .playing },
            playing: { [weak self] in self?.playing($0) },
            playbackFailed: { [weak self] in self?.playbackFailed($0) }
        ))
    }

    @Published public private(set) var state: QuranPlaybackState = .stopped {
        didSet { updateRemoteCommands() }
    }

    @Published public private(set) var currentAyah: AyahNumber?
    @Published public private(set) var error: Error?
    @Published public private(set) var reciters: [Reciter] = []
    @Published public private(set) var activeReciter: Reciter?
    public private(set) var range: AudioRange?
    public private(set) var verseRuns: Runs = .finite(1)
    public private(set) var listRuns: Runs = .finite(1)
    public private(set) var verseDelay: VerseDelay = .none
    public private(set) var repetitionDelay: RepetitionDelay = .none

    /// Snapshot before asynchronous command preparation; a changed value means a newer
    /// playback or stop command owns the session and the prepared command is stale.
    public var commandGeneration: UInt { generation }

    /// The currently displayed reader supplies its ordinary idle Play behavior.
    public var playWhenStopped: (@MainActor () -> Void)? {
        didSet { updateRemoteCommands() }
    }

    public var selectedReciter: Reciter? {
        activeReciter ?? reciters.first { $0.id == ReciterPreferences.shared.lastSelectedReciterId } ?? reciters.first
    }

    public func start() async {
        if reciters.isEmpty {
            reciters = await reciterRetriever.getReciters()
        }
        if remoteCommands == nil {
            remoteCommands = PlaybackRemoteCommands(service: self)
            updateRemoteCommands()
        }
        await restoreRunningDownloadsIfNeeded()
    }

    public func selectReciter(_ reciter: Reciter) {
        stop()
        ReciterPreferences.shared.lastSelectedReciterId = reciter.id
        activeReciter = reciter
    }

    public func continueListening(quran: Quran, fallback: AyahNumber, pageCount: Int) async throws {
        guard pageCount > 0 else { throw ListeningRange.Error.invalidPageCount }
        let checkpoint = progressStore.checkpoint
        if checkpoint?.completed == true { throw QuranPlaybackError.quranCompleted }
        let start = checkpoint?.ayah(in: quran) ?? fallback
        let range = try ListeningRange(from: start, pageCount: pageCount)
        try await play(
            from: range.start, to: range.end,
            reciterID: checkpoint?.reciterID,
            verseRuns: .finite(1), listRuns: .finite(1),
            rate: AudioPreferences.shared.playbackRate,
            verseDelay: .none, repetitionDelay: .none
        )
    }

    public func play(
        from: AyahNumber,
        to: AyahNumber,
        reciterID: Int? = nil,
        verseRuns: Runs,
        listRuns: Runs,
        rate: Float,
        verseDelay: VerseDelay,
        repetitionDelay: RepetitionDelay
    ) async throws {
        try Task.checkCancellation()
        stop()
        let requestID = generation
        error = nil
        range = (from, to)
        self.verseRuns = verseRuns
        self.listRuns = listRuns
        self.verseDelay = verseDelay
        self.repetitionDelay = repetitionDelay
        let task = Task { [self] in
            try await prepareAndPlay(
                from: from, to: to, reciterID: reciterID, rate: rate,
                verseRuns: verseRuns, listRuns: listRuns,
                verseDelay: verseDelay, repetitionDelay: repetitionDelay,
                requestID: requestID
            )
        }
        preparationTask = task
        do {
            try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            if generation == requestID { preparationTask = nil }
        } catch {
            if generation == requestID {
                preparationTask = nil
                if !(error is CancellationError) { self.error = error }
                player.stopAudio()
                state = .stopped
            }
            throw error
        }
    }

    public func pause() {
        player.pauseAudio()
    }

    public func resume() {
        player.resumeAudio()
    }

    public func stepForward() {
        player.stepForward()
    }

    public func stepBackward() {
        player.stepBackward()
    }

    public func setRate(_ rate: Float) {
        AudioPreferences.shared.playbackRate = rate
        player.setRate(rate)
    }

    public func stop() {
        generation &+= 1
        preparationTask?.cancel()
        preparationTask = nil
        activeDownload = nil
        restoredDownloadSubscription = nil
        restoredDownloadObserver = nil
        hasStarted = false
        player.stopAudio()
        state = .stopped
        currentAyah = nil
    }

    public func cancelDownload() async {
        var downloads = restoredDownloadObserver?.runningDownloads ?? []
        if let activeDownload { downloads.insert(activeDownload) }
        stop()
        for download in downloads {
            await download.cancel()
        }
    }

    private let player: QuranAudioPlayer
    private let downloader: QuranAudioDownloader
    private let progressStore: ListeningProgressStore
    private let reciterRetriever: ReciterDataRetriever
    private let recentReciters = RecentRecitersService()
    private var preparationTask: Task<Void, Error>?
    private var generation: UInt = 0
    private var hasStarted = false
    private var activeDownload: DownloadBatchResponse?
    private var remoteCommands: PlaybackRemoteCommands?
    private var didInspectRunningDownloads = false
    private var restoredDownloadObserver: DownloadsObserver<DownloadBatchResponse>?
    private var restoredDownloadSubscription: AnyCancellable?

    func handleRemotePlay() {
        switch state {
        case .stopped: playWhenStopped?()
        case .paused, .playing: resume()
        case .downloading: break
        }
    }

    private func updateRemoteCommands() {
        remoteCommands?.setEnabled(state == .playing || state == .paused)
        if state == .stopped, playWhenStopped != nil {
            remoteCommands?.enableIdlePlay()
        }
    }

    /// Restores download UI after a process relaunch, without restoring playback.
    /// A new user request owns the state as soon as it changes the generation.
    private func restoreRunningDownloadsIfNeeded() async {
        guard !didInspectRunningDownloads, generation == 0, state == .stopped, preparationTask == nil else { return }
        didInspectRunningDownloads = true
        let requestID = generation
        let downloads = Set(await downloader.runningAudioDownloads())
        guard generation == requestID, state == .stopped, preparationTask == nil, !downloads.isEmpty else { return }

        let observer = DownloadsObserver<DownloadBatchResponse>(extractKey: { $0 }, showError: { [weak self] error in
            guard let self, generation == requestID, !(error is CancellationError) else { return }
            self.error = error
        })
        restoredDownloadObserver = observer
        state = .downloading(progress: downloads.map(\.currentProgress.progress).reduce(0, +) / Double(downloads.count))
        await observer.observe(downloads)
        guard generation == requestID, restoredDownloadObserver === observer else { return }
        restoredDownloadSubscription = observer.progressPublisher.sink { [weak self, weak observer] progress in
            guard let self, let observer, generation == requestID else { return }
            let running = observer.runningDownloads
            guard !running.isEmpty else {
                restoredDownloadSubscription = nil
                restoredDownloadObserver = nil
                state = .stopped
                return
            }
            let completed = running.reduce(0) { $0 + (progress[$1] ?? $1.currentProgress.progress) }
            state = .downloading(progress: completed / Double(running.count))
        }
    }

    private func prepareAndPlay(
        from: AyahNumber, to: AyahNumber, reciterID: Int?, rate: Float,
        verseRuns: Runs, listRuns: Runs, verseDelay: VerseDelay,
        repetitionDelay: RepetitionDelay, requestID: UInt
    ) async throws {
        await start()
        try checkCurrent(requestID)
        let reciter = reciterID.flatMap { id in reciters.first { $0.id == id } } ?? selectedReciter
        guard let reciter else { throw QuranPlaybackError.noReciter }
        activeReciter = reciter
        let streaming = AudioPreferences.shared.streamingEnabled
        if streaming {
            if case .gapless = reciter.audioType, !downloader.databaseDownloaded(reciter: reciter) {
                state = .downloading(progress: 0)
                let download = try await downloader.downloadDatabase(reciter: reciter)
                try await acceptDownload(download, requestID: requestID)
            }
        } else if await !downloader.downloaded(reciter: reciter, from: from, to: to) {
            try checkCurrent(requestID)
            state = .downloading(progress: 0)
            let download = try await downloader.download(from: from, to: to, reciter: reciter)
            try await acceptDownload(download, requestID: requestID)
        }
        try checkCurrent(requestID)
        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try AVAudioSession.sharedInstance().setActive(true)
        try await player.play(
            reciter: reciter, rate: rate, from: from, to: to,
            verseRuns: verseRuns, listRuns: listRuns,
            verseDelay: verseDelay, repetitionDelay: repetitionDelay, streaming: streaming
        )
        try checkCurrent(requestID)
        hasStarted = true
        if let currentAyah { saveCheckpoint(at: currentAyah) }
        recentReciters.updateRecentRecitersList(reciter)
        // Player callbacks own state after playback starts, including pauses during preparation.
    }

    private func checkCurrent(_ requestID: UInt) throws {
        try Task.checkCancellation()
        guard generation == requestID else { throw CancellationError() }
    }

    private func acceptDownload(_ download: DownloadBatchResponse, requestID: UInt) async throws {
        do {
            try checkCurrent(requestID)
            try await waitForDownload(download, requestID: requestID)
        } catch is CancellationError {
            await download.cancel()
            throw CancellationError()
        }
    }

    private func waitForDownload(_ download: DownloadBatchResponse, requestID: UInt) async throws {
        activeDownload = download
        defer { if generation == requestID { activeDownload = nil } }
        for try await update in download.progress {
            try checkCurrent(requestID)
            state = .downloading(progress: update.progress)
        }
        try checkCurrent(requestID)
    }

    private func playing(_ ayah: AyahNumber) {
        currentAyah = ayah
        if hasStarted { saveCheckpoint(at: ayah) }
    }

    private func saveCheckpoint(at ayah: AyahNumber) {
        if let activeReciter {
            progressStore.checkpoint = ListeningCheckpoint(ayah: ayah, reciterID: activeReciter.id)
        }
    }

    private func playbackEnded(reason: PlaybackEndReason) {
        if reason == .completed, let range, let activeReciter {
            progressStore.checkpoint = ListeningCheckpoint(
                ayah: range.end.next ?? range.end,
                reciterID: activeReciter.id,
                completed: range.end.next == nil
            )
        }
        hasStarted = false
        currentAyah = nil
        state = .stopped
    }

    private func playbackFailed(_ error: Error) {
        self.error = error
        hasStarted = false
        currentAyah = nil
        state = .stopped
    }
}

public enum QuranPlaybackError: LocalizedError {
    case quranCompleted
    case noReciter

    public var errorDescription: String? {
        switch self {
        case .quranCompleted:
            NSLocalizedString("You have reached the end of the Quran. Choose a new starting point in the app.", comment: "Siri listening completed")
        case .noReciter:
            NSLocalizedString("Choose a reciter in the app before continuing listening.", comment: "Siri reciter missing")
        }
    }
}
