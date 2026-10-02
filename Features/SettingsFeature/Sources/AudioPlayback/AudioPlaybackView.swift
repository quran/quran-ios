//
//  AudioPlaybackView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Localization
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import ReciterService
import SwiftUI
import UIx

struct AudioPlaybackView: View {
    @StateObject var viewModel: AudioPlaybackViewModel

    var body: some View {
        AudioPlaybackViewUI(
            reciterName: viewModel.reciter?.localizedName ?? "",
            playbackRate: $viewModel.playbackRate,
            audioEnd: $viewModel.audioEnd,
            streamingEnabled: $viewModel.streamingEnabled,
            verseRuns: $viewModel.verseRuns,
            verseDelay: $viewModel.verseDelay,
            listRuns: $viewModel.listRuns,
            repetitionDelay: $viewModel.repetitionDelay,
            playbackFooter: viewModel.playbackFooter,
            start: { await viewModel.start() },
            navigateToReciters: { viewModel.navigateToReciters() }
        )
    }
}

private struct AudioPlaybackViewUI: View {
    // MARK: Internal

    let reciterName: String
    @Binding var playbackRate: Float
    @Binding var audioEnd: AudioEnd
    @Binding var streamingEnabled: Bool
    @Binding var verseRuns: Runs
    @Binding var verseDelay: VerseDelay
    @Binding var listRuns: Runs
    @Binding var repetitionDelay: RepetitionDelay
    let playbackFooter: String
    let start: AsyncAction
    let navigateToReciters: Action

    var body: some View {
        NoorList {
            NoorBasicSection(footer: playbackFooter) {
                NoorListItem(
                    image: .init(.reciter),
                    title: .text(l("audio.reciter")),
                    subtitle: .init(text: .text(reciterName), location: .trailing),
                    accessory: .disclosureIndicator,
                    action: .sync { navigateToReciters() }
                )

                NoorMenuRow(
                    title: l("audio.playback-speed"),
                    image: .playbackSpeed,
                    items: PlaybackSpeed.supportedRates,
                    selection: $playbackRate,
                    label: PlaybackSpeed.formatted
                )

                NoorMenuRow(
                    title: l("audio.play-up-to"),
                    image: .playUpTo,
                    items: AudioEnd.playUpToChoices,
                    selection: $audioEnd,
                    label: \.name
                )

                NoorToggleRow(
                    title: l("audio.streaming.title"),
                    image: .stream,
                    isOn: $streamingEnabled
                )
            }

            AudioRepeatSection(
                .eachVerse,
                runs: $verseRuns,
                delays: VerseDelay.sorted,
                delay: $verseDelay,
                delayLabel: \.localizedDescription
            )

            AudioRepeatSection(
                .setOfVerses,
                runs: $listRuns,
                delays: RepetitionDelay.sorted,
                delay: $repetitionDelay,
                delayLabel: \.localizedDescription
            )
        }
        .noorListIconColumn()
        .task { await start() }
    }
}

#Preview {
    struct Container: View {
        @State var playbackRate: Float = 1
        @State var audioEnd = AudioEnd.page
        @State var streamingEnabled = false
        @State var verseRuns = Runs.finite(1)
        @State var verseDelay = VerseDelay.none
        @State var listRuns = Runs.indefinite
        @State var repetitionDelay = RepetitionDelay.oneSecond

        var body: some View {
            AudioPlaybackViewUI(
                reciterName: "Mishari Rashid al-Afasy",
                playbackRate: $playbackRate,
                audioEnd: $audioEnd,
                streamingEnabled: $streamingEnabled,
                verseRuns: $verseRuns,
                verseDelay: $verseDelay,
                listRuns: $listRuns,
                repetitionDelay: $repetitionDelay,
                playbackFooter: l("audio.playback.footer.page"),
                start: {},
                navigateToReciters: {}
            )
        }
    }
    return Container()
}
