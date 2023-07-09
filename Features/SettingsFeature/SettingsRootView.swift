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
            navigateToAudioManager: { await viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { await viewModel.navigateToTranslationsList() },
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
                SimpleListItem(
                    image: NoorSystemImage.audio.image,
                    title: l("audio.download-play-amount"),
                    subtitle: .init(text: audioEnd, location: .trailing),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioEndSelector
                )

                SimpleListItem(
                    image: NoorSystemImage.downloads.image,
                    title: lAndroid("audio_manager"),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioManager
                )
            }

            NoorBasicSection {
                SimpleListItem(
                    image: NoorSystemImage.translation.image,
                    title: lAndroid("prefs_translations"),
                    accessory: .disclosureIndicator,
                    action: navigateToTranslationsList
                )
            }

            NoorBasicSection {
                SimpleListItem(
                    image: NoorSystemImage.share.image,
                    title: l("share_app"),
                    accessory: .disclosureIndicator,
                    action: shareApp
                )

                SimpleListItem(
                    image: NoorSystemImage.star.image,
                    title: l("write_review"),
                    accessory: .disclosureIndicator,
                    action: writeReview
                )

                SimpleListItem(
                    image: NoorSystemImage.mail.image,
                    title: l("contact_us"),
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
