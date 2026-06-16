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

struct AdvancedAudioOptionsRootViewUI: View {
    // MARK: Internal

    let reciterName: String
    let fromVerse: AyahNumber
    let toVerse: AyahNumber
    @Binding var endAt: EndAtChoice
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

            PlayEachVerseSection(
                verseRuns: $verseRuns,
                verseDelay: $verseDelay
            )
            PlaySetChoicesSection(
                listRuns: $listRuns,
                repetitionDelay: $repetitionDelay
            )
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
                HStack {
                    ForEach(PlaybackSpeed.supportedRates, id: \.self) { value in
                        ChoicePill(
                            label: PlaybackSpeed.formatted(value),
                            isSelected: value == rate
                        ) {
                            onSelect(value)
                        }
                    }
                }
            }
        }
    }
}

private struct PlayEachVerseSection: View {
    @Binding var verseRuns: Runs
    @Binding var verseDelay: VerseDelay

    var body: some View {
        Section(header: Text(lAndroid("play_each_verse").replacingOccurrences(of: ":", with: ""))) {
            RunsMenuPicker(runs: $verseRuns)

            VStack(alignment: .leading, spacing: 10) {
                Text(l("audio.verse-delay"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                SegmentedChoicesPicker(title: l("audio.verse-delay"), items: VerseDelay.sorted, selection: $verseDelay) {
                    $0.localizedDescription
                }

                Text(l("audio.verse-delay.description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
    }
}

private struct PlaySetChoicesSection: View {
    @Binding var listRuns: Runs
    @Binding var repetitionDelay: RepetitionDelay

    var body: some View {
        Section(header: Text(lAndroid("play_verses_range").replacingOccurrences(of: ":", with: ""))) {
            RunsMenuPicker(runs: $listRuns)

            VStack(alignment: .leading, spacing: 10) {
                Text(l("audio.repetition-delay"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                SegmentedChoicesPicker(title: l("audio.repetition-delay"), items: RepetitionDelay.sorted, selection: $repetitionDelay) {
                    $0.localizedDescription
                }

                Text(l("audio.repetition-delay.description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        }
    }
}

/// Keeps repeat counts compact in the form while still exposing every supported count.
private struct RunsMenuPicker: View {
    // MARK: Internal

    @Binding var runs: Runs

    var body: some View {
        Menu {
            Button {
                runs = .indefinite
            } label: {
                Label(Runs.indefinite.localizedDescription.capitalized, systemImage: "infinity")
            }

            Divider()

            ForEach(RunsMenuOption.finiteOptions, id: \.self) { option in
                Button {
                    runs = option.runs
                } label: {
                    Text(option.localizedDescription)
                }
            }
        } label: {
            HStack {
                Text(l("audio.repeat-count"))
                    .foregroundStyle(Color(.label))
                Spacer()
                Text(runs.localizedDescription)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
    }
}

private struct SegmentedChoicesPicker<Item: Hashable>: View {
    let title: String
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(items, id: \.self) { item in
                Text(label(item)).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

private enum RunsMenuOption: Hashable {
    case finite(Int)

    static var finiteOptions: [RunsMenuOption] {
        (1 ... 100).map(RunsMenuOption.finite)
    }

    var runs: Runs {
        switch self {
        case .finite(let count): return .finite(count)
        }
    }

    var localizedDescription: String {
        switch self {
        case .finite(let count): return Runs.finite(count).localizedDescription
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

private struct PillChoicesRow<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    let label: (Item) -> String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(items, id: \.self) { item in
                    ChoicePill(label: label(item), isSelected: item == selection) {
                        selection = item
                    }
                }
            }
        }
    }
}

private struct ChoicePill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var verticalPadding: CGFloat = 8
    @ScaledMetric private var horizontalPadding: CGFloat = 16

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.appIdentity.opacity(0.85) : Color(.secondarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}
