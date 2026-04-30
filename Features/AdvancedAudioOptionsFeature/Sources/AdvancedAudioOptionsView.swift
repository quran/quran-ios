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
import QuranKit
import SwiftUI
import UIx

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

private struct AdvancedAudioOptionsRootView: View {
    @StateObject var viewModel: AdvancedAudioOptionsViewModel

    var body: some View {
        AdvancedAudioOptionsRootViewUI(
            reciterName: viewModel.reciter.localizedName,
            fromVerse: viewModel.fromVerse,
            toVerse: viewModel.toVerse,
            endAt: $viewModel.endAt,
            verseRuns: $viewModel.verseRuns,
            listRuns: $viewModel.listRuns,
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

struct AdvancedAudioOptionsRootViewUI: View {
    // MARK: Internal

    let reciterName: String
    let fromVerse: AyahNumber
    let toVerse: AyahNumber
    @Binding var endAt: EndAtChoice
    @Binding var verseRuns: Runs
    @Binding var listRuns: Runs
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
        Form {
            Section {
                ReciterRow(name: reciterName) {
                    navigator?.push {
                        StaticViewControllerRepresentable(viewController: recitersViewController())
                    }
                }
            }

            Section(header: Text(l("audio.playback-ayah-range"))) {
                FromRow(verse: fromVerse) {
                    navigator?.push {
                        StaticViewControllerRepresentable(viewController: fromVerseSelectionViewController)
                    }
                }
                EndAtRow(selection: endAtBinding)
                if endAt == .custom {
                    ToRow(verse: toVerse) {
                        navigator?.push {
                            StaticViewControllerRepresentable(viewController: toVerseSelectionViewController)
                        }
                    }
                }
            }

            PlaybackSpeedSection(
                rate: playbackRate,
                onSelect: updatePlaybackRate
            )

            RunsChoicesSection(title: lAndroid("play_each_verse"), runs: $verseRuns)
            RunsChoicesSection(title: lAndroid("play_verses_range"), runs: $listRuns)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismiss) {
                    Text(lAndroid("cancel"))
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: play) {
                    NoorSystemImage.play.image
                }
            }
        }
    }

    // MARK: Private

    private var endAtBinding: Binding<EndAtChoice> {
        Binding(
            get: { endAt },
            set: { setEndAt($0) }
        )
    }

    private var fromVerseSelectionViewController: UIViewController {
        let verseSelection = AdvancedAudioVersesViewController(suras: fromVerse.quran.suras, selected: fromVerse) { fromVerse in
            updateFromVerseTo(fromVerse)
            navigator?.pop()
        }
        verseSelection.title = l("audio.select-start-verse")
        return verseSelection
    }

    private var toVerseSelectionViewController: UIViewController {
        let verseSelection = AdvancedAudioVersesViewController(suras: toVerse.quran.suras, selected: toVerse) { toVerse in
            updateToVerseTo(toVerse)
            navigator?.pop()
        }
        verseSelection.title = l("audio.select-end-verse")
        return verseSelection
    }
}

// MARK: - Sections

private struct PlaybackSpeedSection: View {
    let rate: Float
    let onSelect: (Float) -> Void

    var body: some View {
        Section(header: Text(l("audio.playback-speed"))) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AdvancedAudioOptionsViewModel.supportedPlaybackRates, id: \.self) { value in
                        SpeedPill(
                            label: formattedSpeed(value),
                            isSelected: value == rate
                        ) {
                            onSelect(value)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
    }
}

private struct RunsChoicesSection: View {
    let title: String
    @Binding var runs: Runs

    var body: some View {
        Section(header: Text(title.replacingOccurrences(of: ":", with: ""))) {
            ChoicesView(items: Runs.sorted, selection: $runs) {
                $0.localizedDescription
            }
        }
    }
}

// MARK: - Rows

private struct ReciterRow: View {
    let name: String
    let action: AsyncAction

    var body: some View {
        NoorListItem(
            title: .text(name),
            accessory: .disclosureIndicator,
            action: action
        )
    }
}

private struct FromRow: View {
    let verse: AyahNumber
    let action: AsyncAction

    var body: some View {
        NoorListItem(
            title: .text(lAndroid("from")),
            subtitle: .init(text: verse.localizedNameWithSuraNumber, location: .trailing),
            accessory: .disclosureIndicator,
            action: action
        )
    }
}

private struct ToRow: View {
    let verse: AyahNumber
    let action: AsyncAction

    var body: some View {
        NoorListItem(
            title: .text(lAndroid("to")),
            subtitle: .init(text: verse.localizedNameWithSuraNumber, location: .trailing),
            accessory: .disclosureIndicator,
            action: action
        )
    }
}

private struct EndAtRow: View {
    @Binding var selection: EndAtChoice

    var body: some View {
        HStack {
            Text(l("audio.end-at"))
            Spacer()
            Picker(l("audio.end-at"), selection: $selection) {
                ForEach(EndAtChoice.allCases, id: \.self) { choice in
                    Text(choice.localizedName).tag(choice)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(.appIdentity)
        }
    }
}

// MARK: - Pills

private struct SpeedPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.appIdentity.opacity(0.85) : Color(.secondarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Speed formatting

private let speedFormatter: NumberFormatter = {
    let nf = NumberFormatter()
    nf.locale = Locale.current.fixedLocaleNumbers()
    nf.minimumFractionDigits = 0
    nf.maximumFractionDigits = 2
    return nf
}()

private func formattedSpeed(_ rate: Float) -> String {
    speedFormatter.format(rate) + "×"
}
