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
            RunsPicker(runs: $verseRuns)

            VStack(alignment: .leading, spacing: 10) {
                Text(l("audio.verse-delay"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                PillChoicesRow(items: VerseDelay.sorted, selection: $verseDelay) {
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
            RunsPicker(runs: $listRuns)

            VStack(alignment: .leading, spacing: 10) {
                Text(l("audio.repetition-delay"))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                PillChoicesRow(items: RepetitionDelay.sorted, selection: $repetitionDelay) {
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

/// Shows the 1×–5× presets alongside a "Custom" choice. Picking "Custom" reveals a wheel
/// picker for any count from 1 to 100, with "Loop" repeated at both ends so it stays
/// reachable without scrolling through the whole range.
private struct RunsPicker: View {
    // MARK: Lifecycle

    init(runs: Binding<Runs>) {
        _runs = runs
        if case .custom(let n) = runs.wrappedValue {
            _customRunsIndex = State(initialValue: n)
        } else {
            _customRunsIndex = State(initialValue: Self.loopTopIndex)
        }
    }

    // MARK: Internal

    @Binding var runs: Runs

    var body: some View {
        PillChoicesRow(items: RunsPreset.allCases, selection: presetSelection) {
            $0.localizedDescription
        }

        if presetSelection.wrappedValue == .custom {
            Picker(l("audio.repetition-count"), selection: customRunsSelection) {
                ForEach(Self.customIndices, id: \.self) { index in
                    Text(Self.label(forCustomIndex: index))
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
        }
    }

    // MARK: Private

    private static let loopTopIndex = 0
    private static let loopBottomIndex = 101
    private static let customIndices = Array(loopTopIndex ... loopBottomIndex)

    @State private var customRunsIndex: Int

    private var presetSelection: Binding<RunsPreset> {
        Binding(
            get: { RunsPreset(runs) },
            set: { preset in
                switch preset {
                case .one: runs = .one
                case .two: runs = .two
                case .three: runs = .three
                case .four: runs = .four
                case .five: runs = .five
                case .custom:
                    if RunsPreset(runs) != .custom {
                        customRunsIndex = Self.loopTopIndex
                        runs = .indefinite
                    }
                }
            }
        )
    }

    private var customRunsSelection: Binding<Int> {
        Binding(
            get: { customRunsIndex },
            set: { index in
                customRunsIndex = index
                runs = (index == Self.loopTopIndex || index == Self.loopBottomIndex) ? .indefinite : .custom(index)
            }
        )
    }

    private static func label(forCustomIndex index: Int) -> String {
        switch index {
        case loopTopIndex, loopBottomIndex: return lAndroid("repeatValues[3]")
        default: return Runs.custom(index).localizedDescription
        }
    }
}

private enum RunsPreset: Hashable, CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case custom

    init(_ runs: Runs) {
        switch runs {
        case .one: self = .one
        case .two: self = .two
        case .three: self = .three
        case .four: self = .four
        case .five: self = .five
        case .indefinite, .custom: self = .custom
        }
    }

    var localizedDescription: String {
        switch self {
        case .one: return Runs.one.localizedDescription
        case .two: return Runs.two.localizedDescription
        case .three: return Runs.three.localizedDescription
        case .four: return Runs.four.localizedDescription
        case .five: return Runs.five.localizedDescription
        case .custom: return l("audio.repetition-count")
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
