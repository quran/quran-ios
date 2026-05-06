//
//  AudioPlaybackController.md
//  QuranEngineApp
//
//  Created by aom on 3/9/26.
//


import Foundation
import MediaPlayer
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterService

@MainActor
public final class AudioPlaybackController {
    public struct PlaybackRequest: Equatable {
        public let start: AyahNumber
        public let end: AyahNumber
        public let verseRuns: Runs
        public let listRuns: Runs
    }

    public enum PlaybackState: Equatable {
        case stopped
        case playing
        case paused
        case downloading(progress: Double)
    }

    public enum AudioAvailability: Equatable {
        case downloaded
        case downloading(progress: Double)
        case downloadRequired
    }

    public struct Snapshot {
        public let playbackState: PlaybackState
        public let request: PlaybackRequest?
        public let currentAyah: AyahNumber?
        public let reciter: Reciter?

        public var surahNumber: Int? {
            request?.start.sura.suraNumber
        }

        public var surahTitle: String? {
            surahNumber.map { AudioPlaybackController.surahTitle(for: $0, withNumber: true) }
        }

        public var reciterName: String? {
            reciter?.localizedName
        }
    }

    public typealias Observer = @MainActor (Snapshot) -> Void

    private let audioPlayer: QuranAudioPlayer
    private let downloader: QuranAudioDownloader
    private let recentRecitersService: RecentRecitersService
    private let preferences = ReciterPreferences.shared
    private let reciterRetriever: ReciterDataRetriever
    private let nowPlaying = NowPlayingUpdater(center: .default())
    private var remoteCommandsHandler: AudioPlaybackRemoteCommandsHandler?
    private var reciters: [Reciter] = []
    private var currentRequest: PlaybackRequest?
    private var currentAyah: AyahNumber?
    private var currentReciter: Reciter?
    private var playbackState: PlaybackState = .stopped
    private var observers: [UUID: Observer] = [:]

    var player: QuranAudioPlayer { audioPlayer }
    var audioDownloader: QuranAudioDownloader { downloader }

    public init(
        audioPlayer: QuranAudioPlayer,
        downloader: QuranAudioDownloader,
        reciterRetriever: ReciterDataRetriever,
        recentRecitersService: RecentRecitersService
    ) {
        self.audioPlayer = audioPlayer
        self.downloader = downloader
        self.reciterRetriever = reciterRetriever
        self.recentRecitersService = recentRecitersService

        setUpAudioPlayerActions()
        setUpRemoteCommandHandler()
        updateRemoteCommandAvailability()
    }

    public var snapshot: Snapshot {
        Snapshot(
            playbackState: playbackState,
            request: currentRequest,
            currentAyah: currentAyah,
            reciter: selectedReciter
        )
    }

    @discardableResult
    public func addObserver(_ observer: @escaping Observer) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(snapshot)
        return id
    }

    public func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    public func getReciters() async -> [Reciter] {
        if reciters.isEmpty {
            reciters = await reciterRetriever.getReciters()
            publishSnapshot()
        }
        return reciters
    }

    public func audioAvailability(
        reciter: Reciter,
        from start: AyahNumber,
        to end: AyahNumber
    ) async -> AudioAvailability {
        if await downloader.downloaded(reciter: reciter, from: start, to: end) {
            return .downloaded
        }

        if let runningDownload = Set(await downloader.runningAudioDownloads()).firstMatches(reciter) {
            return .downloading(progress: runningDownload.currentProgress.progress)
        }

        return .downloadRequired
    }

    public func playSurah(_ surahNumber: Int) async throws {
        let quran = Quran.hafsMadani1405
        guard surahNumber >= 1, surahNumber <= quran.suras.count else {
            return
        }

        let sura = quran.suras[surahNumber - 1]
        try await play(from: sura.firstVerse, to: sura.lastVerse)
    }

    public func play(
        from: AyahNumber,
        to: AyahNumber?,
        verseRuns: Runs = .one,
        listRuns: Runs = .one
    ) async throws {
        guard let reciter = await resolveSelectedReciter() else {
            return
        }

        if playbackState != .stopped {
            audioPlayer.stopAudio()
        }

        let end = to ?? from.page.lastVerse
        let request = PlaybackRequest(start: from, end: end, verseRuns: verseRuns, listRuns: listRuns)
        currentRequest = request
        currentAyah = from
        currentReciter = reciter
        recentRecitersService.updateRecentRecitersList(reciter)
        publishSnapshot()
        updateNowPlayingMetadata()

        let alreadyDownloaded = await downloader.downloaded(
            reciter: reciter,
            from: from,
            to: end
        )

        do {
            if !alreadyDownloaded {
                updatePlaybackState(.downloading(progress: 0))
                let response = try await downloader.download(
                    from: from,
                    to: end,
                    reciter: reciter
                )
                for try await progress in response.progress {
                    updatePlaybackState(.downloading(progress: progress.progress))
                }
            }

            try await audioPlayer.play(
                reciter: reciter,
                rate: AudioPreferences.shared.playbackRate,
                from: from,
                to: end,
                verseRuns: verseRuns,
                listRuns: listRuns
            )
            updatePlaybackState(.playing)
            updateNowPlayingMetadata()
        } catch {
            currentAyah = nil
            updatePlaybackState(.stopped)
            updateNowPlayingMetadata(playbackRate: 0)
            throw error
        }
    }

    public func setReciter(_ reciter: Reciter) {
        if !reciters.contains(reciter) {
            reciters.append(reciter)
            reciters.sort { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
        }
        currentReciter = reciter
        preferences.lastSelectedReciterId = reciter.id
        publishSnapshot()
        updateNowPlayingMetadata()
    }

    public func pause() {
        audioPlayer.pauseAudio()
        updatePlaybackState(.paused)
        updateNowPlayingMetadata(playbackRate: 0)
    }

    public func resume() {
        audioPlayer.resumeAudio()
        updatePlaybackState(.playing)
        updateNowPlayingMetadata(playbackRate: AudioPreferences.shared.playbackRate)
    }

    public func stop() {
        audioPlayer.stopAudio()
        currentAyah = nil
        updatePlaybackState(.stopped)
        updateNowPlayingMetadata(playbackRate: 0)
    }

    public func stepForward() {
        audioPlayer.stepForward()
        updatePlaybackState(.playing)
        updateNowPlayingMetadata(playbackRate: AudioPreferences.shared.playbackRate)
    }

    public func stepBackward() {
        audioPlayer.stepBackward()
        updatePlaybackState(.playing)
        updateNowPlayingMetadata(playbackRate: AudioPreferences.shared.playbackRate)
    }

    public func setRate(_ rate: Float) {
        AudioPreferences.shared.playbackRate = rate
        audioPlayer.setRate(rate)

        if case .playing = playbackState {
            updateNowPlayingMetadata(playbackRate: rate)
        }
    }

    public nonisolated static func surahTitle(for surahNumber: Int, withNumber: Bool = false) -> String {
        let name = audioPlaybackChapterNames[safe: surahNumber - 1] ?? "Surah \(surahNumber)"
        if withNumber {
            return "\(surahNumber). \(name)"
        }
        return name
    }

    private var selectedReciter: Reciter? {
        currentReciter ?? selectedReciter(from: reciters)
    }

    private func resolveSelectedReciter() async -> Reciter? {
        let reciters = await getReciters()
        let reciter = currentReciter.flatMap { current in
            reciters.first { $0.id == current.id }
        } ?? selectedReciter(from: reciters) ?? reciters.first
        currentReciter = reciter
        publishSnapshot()
        return reciter
    }

    private func publishSnapshot() {
        let snapshot = snapshot
        let callbacks = Array(observers.values)
        for callback in callbacks {
            callback(snapshot)
        }
    }

    private func updatePlaybackState(_ state: PlaybackState) {
        playbackState = state
        publishSnapshot()
        updateRemoteCommandAvailability()
    }

    private func updateRemoteCommandAvailability() {
        remoteCommandsHandler?.update(
            state: playbackState,
            hasPlaybackRequest: currentRequest != nil
        )
    }

    private func updateNowPlayingMetadata(playbackRate: Float? = nil) {
        guard let request = currentRequest else {
            return
        }

        let rate: Float
        if let playbackRate {
            rate = playbackRate
        } else {
            switch playbackState {
            case .playing: rate = AudioPreferences.shared.playbackRate
            case .paused, .stopped, .downloading: rate = 0
            }
        }

        nowPlaying.update(info: .init(
            title: Self.surahTitle(for: request.start.sura.suraNumber, withNumber: true),
            artist: selectedReciter?.localizedName ?? "",
            image: nil
        ))
        nowPlaying.update(rate: rate)
    }

    private func setUpAudioPlayerActions() {
        let actions = QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.playbackEnded() },
            playbackPaused: { [weak self] in self?.playbackPaused() },
            playbackResumed: { [weak self] in self?.playbackResumed() },
            playing: { [weak self] in self?.playing(ayah: $0) }
        )
        audioPlayer.setActions(actions)
    }

    private func playbackEnded() {
        currentAyah = nil
        updatePlaybackState(.stopped)
        updateNowPlayingMetadata(playbackRate: 0)
    }

    private func playbackPaused() {
        updatePlaybackState(.paused)
        updateNowPlayingMetadata(playbackRate: 0)
    }

    private func playbackResumed() {
        updatePlaybackState(.playing)
        updateNowPlayingMetadata(playbackRate: AudioPreferences.shared.playbackRate)
    }

    private func playing(ayah: AyahNumber) {
        currentAyah = ayah
        if case .downloading = playbackState {
            updatePlaybackState(.playing)
            updateNowPlayingMetadata(playbackRate: AudioPreferences.shared.playbackRate)
        } else {
            publishSnapshot()
        }
    }

    private func setUpRemoteCommandHandler() {
        let actions = AudioPlaybackRemoteCommandActions(
            play: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.handlePlayCommand()
                }
            },
            pause: { [weak self] in self?.pause() },
            togglePlayPause: { [weak self] in self?.togglePlayPause() },
            nextTrack: { [weak self] in self?.stepForward() },
            previousTrack: { [weak self] in self?.stepBackward() }
        )
        remoteCommandsHandler = AudioPlaybackRemoteCommandsHandler(center: .shared(), actions: actions)
    }

    private func handlePlayCommand() async {
        switch playbackState {
        case .paused:
            resume()
        case .stopped:
            guard let currentRequest else {
                return
            }
            do {
                try await play(
                    from: currentRequest.start,
                    to: currentRequest.end,
                    verseRuns: currentRequest.verseRuns,
                    listRuns: currentRequest.listRuns
                )
            } catch {
            }
        case .playing, .downloading:
            break
        }
    }

    private func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused:
            resume()
        case .stopped, .downloading:
            Task { @MainActor in
                await handlePlayCommand()
            }
        }
    }

    private func selectedReciter(from reciters: [Reciter]) -> Reciter? {
        reciters.first { $0.id == preferences.lastSelectedReciterId }
    }
}

@MainActor
private struct AudioPlaybackRemoteCommandActions {
    let play: () -> Void
    let pause: () -> Void
    let togglePlayPause: () -> Void
    let nextTrack: () -> Void
    let previousTrack: () -> Void
}

@MainActor
private final class AudioPlaybackRemoteCommandsHandler {
    init(center: MPRemoteCommandCenter, actions: AudioPlaybackRemoteCommandActions) {
        self.center = center
        self.actions = actions
        setUpRemoteControlEvents()
    }

    func update(state: AudioPlaybackController.PlaybackState, hasPlaybackRequest: Bool) {
        switch state {
        case .playing, .paused:
            setTransportCommandsEnabled(true)
        case .downloading:
            setTransportCommandsEnabled(false)
            center.playCommand.isEnabled = false
        case .stopped:
            setTransportCommandsEnabled(false)
            center.playCommand.isEnabled = hasPlaybackRequest
        }
    }

    private let center: MPRemoteCommandCenter
    private let actions: AudioPlaybackRemoteCommandActions

    private func setUpRemoteControlEvents() {
        center.playCommand.addTarget { [weak self] _ in
            self?.actions.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.actions.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.actions.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.actions.nextTrack()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.actions.previousTrack()
            return .success
        }

        let unusedCommands = [
            center.seekForwardCommand,
            center.seekBackwardCommand,
            center.skipForwardCommand,
            center.skipBackwardCommand,
            center.ratingCommand,
            center.changePlaybackRateCommand,
            center.likeCommand,
            center.dislikeCommand,
            center.bookmarkCommand,
            center.changePlaybackPositionCommand,
        ]
        for command in unusedCommands {
            command.isEnabled = false
        }
    }

    private func setTransportCommandsEnabled(_ enabled: Bool) {
        let commands = [
            center.playCommand,
            center.pauseCommand,
            center.togglePlayPauseCommand,
            center.nextTrackCommand,
            center.previousTrackCommand,
        ]
        for command in commands {
            command.isEnabled = enabled
        }
    }
}

private let audioPlaybackChapterNames = [
    "Al-Fatihah", "Al-Baqarah", "Ali 'Imran", "An-Nisa", "Al-Ma'idah",
    "Al-An'am", "Al-A'raf", "Al-Anfal", "At-Taubah", "Yunus",
    "Hud", "Yusuf", "Ar-Ra'd", "Ibrahim", "Al-Hijr",
    "An-Nahl", "Al-Isra", "Al-Kahf", "Maryam", "Ta-Ha",
    "Al-Anbiya", "Al-Hajj", "Al-Mu'minun", "An-Nur", "Al-Furqan",
    "Ash-Shu'ara", "An-Naml", "Al-Qasas", "Al-'Ankabut", "Ar-Rum",
    "Luqman", "As-Sajdah", "Al-Ahzab", "Saba", "Fatir",
    "Ya-Sin", "As-Saffat", "Sad", "Az-Zumar", "Ghafir",
    "Fussilat", "Ash-Shura", "Az-Zukhruf", "Ad-Dukhan", "Al-Jathiya",
    "Al-Ahqaf", "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf",
    "Adh-Dhariyat", "At-Tur", "An-Najm", "Al-Qamar", "Ar-Rahman",
    "Al-Waqi'ah", "Al-Hadid", "Al-Mujadilah", "Al-Hashr", "Al-Mumtahanah",
    "As-Saff", "Al-Jumu'ah", "Al-Munafiqun", "At-Taghabun", "At-Talaq",
    "At-Tahrim", "Al-Mulk", "Al-Qalam", "Al-Haqqah", "Al-Ma'arij",
    "Nuh", "Al-Jinn", "Al-Muzzammil", "Al-Muddaththir", "Al-Qiyamah",
    "Ad-Dahr", "Al-Mursalat", "An-Naba", "An-Nazi'at", "Abasa",
    "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Inshiqaq", "Al-Buruj",
    "At-Tariq", "Al-A'la", "Al-Ghashiyah", "Al-Fajr", "Al-Balad",
    "Ash-Shams", "Al-Lail", "Ad-Duhaa", "Ash-Sharh", "At-Tin",
    "Al-'Alaq", "Al-Qadr", "Al-Bayyinah", "Az-Zilzal", "Al-Adiyat",
    "Al-Qari'ah", "At-Takathur", "Al-'Asr", "Al-Humazah", "Al-Fil",
    "Quraysh", "Al-Ma'un", "Al-Kawthar", "Al-Kafirun", "An-Nasr",
    "Al-Masad", "Al-Ikhlas", "Al-Falaq", "An-Nas",
]

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
