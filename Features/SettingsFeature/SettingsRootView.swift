//
//  SettingsRootView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//
//

import Localization
import NoorUI
import SwiftUI
import UIx

struct SettingsRootView: View {
    @StateObject var viewModel: SettingsRootViewModel

    var body: some View {
        SettingsRootViewUI(
            theme: $viewModel.theme,
            audioEnd: viewModel.audioEnd.name,
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() }
        )
    }
}

private struct SettingsRootViewUI: View {
    @Binding var theme: Theme
    let audioEnd: String
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let navigateToReadingSelector: AsyncAction
    let shareApp: AsyncAction
    let writeReview: AsyncAction
    let contactUs: AsyncAction
    let navigateToDiagnotics: AsyncAction

    var body: some View {
        NoorList {
            NoorBasicSection {
                VStack {
                    ThemeSelector(theme: $theme)
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.mushafs),
                    title: .text(l("reading.selector.title")),
                    accessory: .disclosureIndicator,
                    action: navigateToReadingSelector
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.audio),
                    title: .text(l("audio.download-play-amount")),
                    subtitle: .init(text: audioEnd, location: .trailing),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioEndSelector
                )

                NoorListItem(
                    image: .init(.downloads),
                    title: .text(lAndroid("audio_manager")),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioManager
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.translation),
                    title: .text(lAndroid("prefs_translations")),
                    accessory: .disclosureIndicator,
                    action: navigateToTranslationsList
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.share),
                    title: .text(l("setting.share_app")),
                    accessory: .disclosureIndicator,
                    action: shareApp
                )

                NoorListItem(
                    image: .init(.star),
                    title: .text(l("setting.write_review")),
                    accessory: .disclosureIndicator,
                    action: writeReview
                )

                NoorListItem(
                    image: .init(.mail),
                    title: .text(l("setting.contact_us")),
                    accessory: .disclosureIndicator,
                    action: contactUs
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.debug),
                    title: .text(l("diagnostics.title")),
                    accessory: .disclosureIndicator,
                    action: navigateToDiagnotics
                )
            }
        }
    }
}

struct SettingsRootView_Previews: PreviewProvider {
    struct Container: View {
        @State var theme: Theme

        var body: some View {
            SettingsRootViewUI(
                theme: $theme,
                audioEnd: "Surah",
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {}
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(theme: .auto)
        }
    }
}
