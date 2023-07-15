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
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() }
        )
    }
}

private struct SettingsRootViewUI: View {
    @Binding var theme: Theme
    let audioEnd: String
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let shareApp: AsyncAction
    let writeReview: AsyncAction
    let contactUs: AsyncAction

    var body: some View {
        NoorList {
            NoorBasicSection {
                VStack {
                    ThemeSelector(theme: $theme)
                }
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
                    title: .text(l("share_app")),
                    accessory: .disclosureIndicator,
                    action: shareApp
                )

                NoorListItem(
                    image: .init(.star),
                    title: .text(l("write_review")),
                    accessory: .disclosureIndicator,
                    action: writeReview
                )

                NoorListItem(
                    image: .init(.mail),
                    title: .text(l("contact_us")),
                    accessory: .disclosureIndicator,
                    action: contactUs
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
                shareApp: {},
                writeReview: {},
                contactUs: {}
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
