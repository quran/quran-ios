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
            verseRuns: $viewModel.verseRuns,
            listRuns: $viewModel.listRuns,
            verseDelay: $viewModel.verseDelay,
            repetitionDelay: $viewModel.repetitionDelay,
            playbackRate: viewModel.playbackRate,
            dismiss: { viewModel.dismiss() },
            play: { viewModel.play() },
            updateFromVerseTo: { viewModel.updateFromVerseTo($0) },
            updateToVerseTo: { viewModel.updateToVerseTo($0) },
            setEndAt: { viewModel.setEndAt($0) },
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
    @Binding var verseRuns: Runs
    @Binding var listRuns: Runs
    @Binding var verseDelay: VerseDelay
    @Binding var repetitionDelay: RepetitionDelay
    let playbackRate: Float
    let dismiss: @MainActor @Sendable () -> Void
    let play: @MainActor @Sendable () -> Void
    let updateFromVerseTo: ItemAction<AyahNumber>
    let updateToVerseTo: ItemAction<AyahNumber>
    let setEndAt: (EndAtChoice) -> Void
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
                    selection: endAtSelection,
                    value: endAt.localizedName
                ) { choice in
                    Text(choice.localizedName)
                }
            }

            NoorBasicSection(
                title: sectionTitle(lAndroid("play_each_verse")),
                footer: l("audio.verse-delay.description")
            ) {
                RepeatCountRow(image: .repeatVerse, runs: $verseRuns)

                NoorMenuRow(
                    title: l("audio.verse-delay"),
                    image: .pauseDelay,
                    items: VerseDelay.sorted,
                    selection: $verseDelay,
                    label: \.localizedDescription
                )
            }

            NoorBasicSection(
                title: sectionTitle(lAndroid("play_verses_range")),
                footer: l("audio.repetition-delay.description")
            ) {
                RepeatCountRow(image: .repeatRange, runs: $listRuns)

                NoorMenuRow(
                    title: l("audio.repetition-delay"),
                    image: .pauseDelay,
                    items: RepetitionDelay.sorted,
                    selection: $repetitionDelay,
                    label: \.localizedDescription
                )
            }
        }
        .noorListIconColumn()
        .navigationTitle(l("audio.options"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: dismiss)

            ToolbarItem(placement: .confirmationAction) {
                Button(action: play) {
                    NoorSystemImage.play.image
                }
                .accessibilityLabel(lAndroid("play"))
            }
        }
    }

    // MARK: Private

    private var playbackRateBinding: Binding<Float> {
        Binding(
            get: { playbackRate },
            set: { updatePlaybackRate($0) }
        )
    }

    /// Custom isn't a menu item, so it checks none of them.
    private var endAtSelection: Binding<EndAtChoice?> {
        Binding(
            get: { endAt == .custom ? nil : endAt },
            set: { choice in
                if let choice {
                    setEndAt(choice)
                }
            }
        )
    }

    /// The Android section titles end with a colon.
    private func sectionTitle(_ title: String) -> String {
        title.replacingOccurrences(of: ":", with: "")
    }
}
