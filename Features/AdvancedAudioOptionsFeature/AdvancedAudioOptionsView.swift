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
            verseRuns: $viewModel.verseRuns,
            listRuns: $viewModel.listRuns,
            dismiss: { viewModel.dismiss() },
            play: { viewModel.play() },
            lastPageTapped: { viewModel.setLastVerseInPage() },
            lastSuraTapped: { viewModel.setLastVerseInSura() },
            lastJuzTapped: { viewModel.setLastVerseInJuz() },
            lastQuranAyahTapped: { viewModel.setLastVerseInQuran() },
            updateFromVerseTo: { viewModel.updateFromVerseTo($0) },
            updateToVerseTo: { viewModel.updateToVerseTo($0) },
            recitersViewController: { viewModel.recitersViewController() }
        )
    }
}

struct AdvancedAudioOptionsRootViewUI: View {
    // MARK: Internal

    let reciterName: String
    let fromVerse: AyahNumber
    let toVerse: AyahNumber
    @Binding var verseRuns: Runs
    @Binding var listRuns: Runs
    let dismiss: @MainActor @Sendable () -> Void
    let play: @MainActor @Sendable () -> Void
    let lastPageTapped: @MainActor @Sendable () -> Void
    let lastSuraTapped: @MainActor @Sendable () -> Void
    let lastJuzTapped: @MainActor @Sendable () -> Void
    let lastQuranAyahTapped: @MainActor @Sendable () -> Void
    let updateFromVerseTo: ItemAction<AyahNumber>
    let updateToVerseTo: ItemAction<AyahNumber>
    let recitersViewController: () -> UIViewController

    @Environment(\.navigator) var navigator: Navigator?

    var body: some View {
        Form {
            ReciterSection(name: reciterName, image: nil) {
                navigator?.push {
                    StaticViewControllerRepresentable(viewController: recitersViewController())
                }
            }

            Section(header: Text(l("audio.adjust-end-verse-to-the-end.label"))) {
                HStack {
                    ActiveRoundedButton(label: lAndroid("quran_page"), action: lastPageTapped)
                    Spacer()
                    ActiveRoundedButton(label: l("surah"), action: lastSuraTapped)
                    Spacer()
                    ActiveRoundedButton(label: lAndroid("quran_juz2"), action: lastJuzTapped)
                    Spacer()
                    ActiveRoundedButton(label: l("quran_alquran"), action: lastQuranAyahTapped)
                }
            }

            Section(header: Text(l("audio.playing-verses.label"))) {
                VerseStaticView(label: lAndroid("from"), verse: fromVerse) {
                    navigator?.push {
                        StaticViewControllerRepresentable(viewController: fromVerseSelectionViewController)
                    }
                }
                VerseStaticView(label: lAndroid("to"), verse: toVerse) {
                    navigator?.push {
                        StaticViewControllerRepresentable(viewController: toVerseSelectionViewController)
                    }
                }
            }

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
        verseSelection.title = l("audio.select-start-verse")
        return verseSelection
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

private struct VerseStaticView: View {
    let label: String
    let verse: AyahNumber
    let action: AsyncAction

    var body: some View {
        NoorListItem(
            title: .text(label),
            subtitle: .init(text: verse.localizedNameWithSuraNumber, location: .trailing),
            accessory: .disclosureIndicator,
            action: action
        )
    }
}

private struct ReciterSection: View {
    let name: String
    let image: String?
    let action: AsyncAction

    var body: some View {
        Section {
            NoorListItem(
                title: .text(name),
                accessory: .disclosureIndicator,
                action: action
            )
        }
    }
}

struct AdvancedAudioOptionsPreview: View {
    @State var verseRuns: Runs = .one
    @State var listRuns: Runs = .three

    var body: some View {
        AdvancedAudioOptionsRootViewUI(
            reciterName: "Mishary",
            fromVerse: Quran.hafsMadani1405.suras[0].firstVerse,
            toVerse: Quran.hafsMadani1405.suras[0].lastVerse,
            verseRuns: $verseRuns,
            listRuns: $listRuns,
            dismiss: {},
            play: {},
            lastPageTapped: {},
            lastSuraTapped: {},
            lastJuzTapped: {},
            lastQuranAyahTapped: {},
            updateFromVerseTo: { _ in },
            updateToVerseTo: { _ in },
            recitersViewController: { UIViewController() }
        )
    }
}

#Preview {
    AdvancedAudioOptionsPreview()
}
