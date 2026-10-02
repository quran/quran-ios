//
//  AdvancedAudioOptionsView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/24/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
struct AdvancedAudioOptionsView: View {
    @StateObject var viewModel: AdvancedAudioOptionsViewModel

    var body: some View {
        CocoaNavigationView {
            AdvancedAudioOptionsRootView(viewModel: viewModel)
        }
        .standardAppearance(.opaqueBackground().backgroundColor(.systemBackground))
        .scrollEdgeAppearance(.opaqueBackground().backgroundColor(.systemBackground))
    }
}

@MainActor
private struct AdvancedAudioOptionsRootView: View {
    @StateObject var viewModel: AdvancedAudioOptionsViewModel

    var body: some View {
        AdvancedAudioOptionsRootViewUI(
            reciterName: viewModel.reciter.localizedName,
            fromVerse: viewModel.fromVerse,
            toVerse: viewModel.toVerse,
            endAt: viewModel.endAt,
            playUpToSelection: viewModel.playUpToSelection,
            verseRuns: $viewModel.verseRuns,
            listRuns: $viewModel.listRuns,
            verseDelay: $viewModel.verseDelay,
            repetitionDelay: $viewModel.repetitionDelay,
            playbackRate: viewModel.playbackRate,
            dismiss: { viewModel.dismiss() },
            play: { viewModel.play() },
            updateFromVerseTo: { viewModel.updateFromVerseTo($0) },
            updateToVerseTo: { viewModel.updateToVerseTo($0) },
            selectPlayUpTo: { viewModel.selectPlayUpTo($0) },
            updatePlaybackRate: { viewModel.updatePlaybackRate(to: $0) },
            recitersViewController: { viewModel.recitersViewController() }
        )
    }
}

@MainActor
struct AdvancedAudioOptionsRootViewUI: View {
    // MARK: Internal

    let reciterName: String
    let fromVerse: AyahNumber
    let toVerse: AyahNumber
    let endAt: EndAtChoice
    let playUpToSelection: EndAtChoice?
    @Binding var verseRuns: Runs
    @Binding var listRuns: Runs
    @Binding var verseDelay: VerseDelay
    @Binding var repetitionDelay: RepetitionDelay
    let playbackRate: Float
    let dismiss: @MainActor @Sendable () -> Void
    let play: @MainActor @Sendable () -> Void
    let updateFromVerseTo: ItemAction<AyahNumber>
    let updateToVerseTo: ItemAction<AyahNumber>
    let selectPlayUpTo: (EndAtChoice) -> Void
    let updatePlaybackRate: (Float) -> Void
    let recitersViewController: () -> UIViewController

    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        NoorList {
            NoorBasicSection {
                NoorListItem(
                    image: .init(.reciter),
                    title: .text(l("audio.reciter")),
                    subtitle: .init(text: .text(reciterName), location: .trailing),
                    accessory: .disclosureIndicator,
                    action: .sync {
                        navigator?.push {
                            StaticViewControllerRepresentable(viewController: recitersViewController())
                        }
                    }
                )

                NoorMenuRow(
                    title: l("audio.playback-speed"),
                    image: .playbackSpeed,
                    items: PlaybackSpeed.supportedRates,
                    selection: playbackRateBinding,
                    label: PlaybackSpeed.formatted
                )
            }

            NoorBasicSection(
                title: l("audio.playback-ayah-range"),
                footer: l("audio.end-at.description")
            ) {
                AyahRangePicker(
                    fromVerse: fromVerse,
                    toVerse: toVerse,
                    updateFromVerseTo: updateFromVerseTo,
                    updateToVerseTo: updateToVerseTo
                )

                NoorMenuRow(
                    title: l("audio.play-up-to"),
                    image: .playUpTo,
                    items: EndAtChoice.menuChoices,
                    selectedItem: playUpToSelection,
                    value: endAt.localizedName,
                    onSelect: selectPlayUpTo
                ) { choice in
                    Text(choice.localizedName)
                }
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
        .navigationTitle(l("audio.options"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: dismiss)

            PrimaryActionToolbarItem(
                image: .play,
                accessibilityLabel: lAndroid("play"),
                action: play
            )
        }
    }

    // MARK: Private

    private var playbackRateBinding: Binding<Float> {
        Binding(
            get: { playbackRate },
            set: { updatePlaybackRate($0) }
        )
    }
}
