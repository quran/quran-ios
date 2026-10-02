//
//  AudioPlaybackViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Combine
import Localization
import QueuePlayer
import QuranAudio
import QuranAudioKit
import ReciterListFeature
import ReciterService
import UIKit
import VLogging

/// Settings › Audio Playback: the audio preferences the banner plays with.
/// Every change saves right away, and changes made elsewhere show up live.
@MainActor
final class AudioPlaybackViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        reciterRetriever: ReciterDataRetriever,
        recentRecitersService: RecentRecitersService,
        reciterListBuilder: ReciterListBuilder,
        navigationController: UINavigationController?
    ) {
        self.reciterRetriever = reciterRetriever
        self.recentRecitersService = recentRecitersService
        self.reciterListBuilder = reciterListBuilder
        self.navigationController = navigationController

        selectedReciterId = reciterPreferences.lastSelectedReciterId
        playbackRate = audioPreferences.playbackRate
        audioEnd = audioPreferences.audioEnd
        streamingEnabled = audioPreferences.streamingEnabled
        verseRuns = audioPreferences.verseRuns
        verseDelay = audioPreferences.verseDelay
        listRuns = audioPreferences.listRuns
        repetitionDelay = audioPreferences.repetitionDelay

        reciterPreferences.$lastSelectedReciterId.assign(to: &$selectedReciterId)
        audioPreferences.$playbackRate.assign(to: &$playbackRate)
        audioPreferences.$audioEnd.assign(to: &$audioEnd)
        audioPreferences.$streamingEnabled.assign(to: &$streamingEnabled)
        audioPreferences.$verseRuns.assign(to: &$verseRuns)
        audioPreferences.$verseDelay.assign(to: &$verseDelay)
        audioPreferences.$listRuns.assign(to: &$listRuns)
        audioPreferences.$repetitionDelay.assign(to: &$repetitionDelay)
    }

    // MARK: Internal

    @Published private(set) var reciters: [Reciter] = []
    @Published private(set) var selectedReciterId: Int

    @Published var playbackRate: Float {
        didSet { save(playbackRate, to: \.playbackRate) }
    }

    @Published var audioEnd: AudioEnd {
        didSet { save(audioEnd, to: \.audioEnd) }
    }

    @Published var streamingEnabled: Bool {
        didSet { save(streamingEnabled, to: \.streamingEnabled) }
    }

    @Published var verseRuns: Runs {
        didSet { save(verseRuns, to: \.verseRuns) }
    }

    @Published var verseDelay: VerseDelay {
        didSet { save(verseDelay, to: \.verseDelay) }
    }

    @Published var listRuns: Runs {
        didSet { save(listRuns, to: \.listRuns) }
    }

    @Published var repetitionDelay: RepetitionDelay {
        didSet { save(repetitionDelay, to: \.repetitionDelay) }
    }

    /// The reciter the banner plays with. Like the banner, it falls back to the first
    /// reciter when the saved one isn't available.
    var reciter: Reciter? {
        reciters.first { $0.id == selectedReciterId } ?? reciters.first
    }

    /// Where playback stops, and what streaming changes about it.
    var playbackFooter: String {
        switch audioEnd {
        case .page: l("audio.playback.footer.page")
        case .sura: l("audio.playback.footer.surah")
        case .juz: l("audio.playback.footer.juz")
        case .quran: l("audio.playback.footer.quran")
        }
    }

    func start() async {
        reciters = await reciterRetriever.getReciters()
    }

    func navigateToReciters() {
        logger.info("Settings: Audio Playback navigateToReciters")
        let viewController = reciterListBuilder.build(withListener: self, standalone: false)
        navigationController?.pushViewController(viewController, animated: true)
    }

    // MARK: Private

    private let reciterRetriever: ReciterDataRetriever
    private let recentRecitersService: RecentRecitersService
    private let reciterListBuilder: ReciterListBuilder
    private weak var navigationController: UINavigationController?

    private let audioPreferences = AudioPreferences.shared
    private let reciterPreferences = ReciterPreferences.shared

    private func save<Value: Equatable>(_ value: Value, to keyPath: ReferenceWritableKeyPath<AudioPreferences, Value>) {
        guard audioPreferences[keyPath: keyPath] != value else { return }
        audioPreferences[keyPath: keyPath] = value
    }
}

extension AudioPlaybackViewModel: ReciterListListener {
    /// The reciter list pops itself after the selection.
    func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("Settings: Audio Playback selected reciter \(reciter.id)")
        reciterPreferences.lastSelectedReciterId = reciter.id
        recentRecitersService.updateRecentRecitersList(reciter)
    }
}
