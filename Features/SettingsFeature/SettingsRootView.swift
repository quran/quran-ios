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
            appearanceMode: $viewModel.appearanceMode,
            error: $viewModel.error,
            audioEnd: viewModel.audioEnd.name,
            isAuthenticated: viewModel.isAuthenticated,
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() },
            refreshAuthenticationState: { await viewModel.refreshAuthenticationState() },
            loginAction: { await viewModel.loginToQuranCom() },
            logoutAction: { await viewModel.logoutFromQuranCom() }
        )
    }
}

private struct SettingsRootViewUI: View {
    @Binding var appearanceMode: AppearanceMode
    @Binding var error: Error?

    let audioEnd: String
    let isAuthenticated: Bool
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let navigateToReadingSelector: AsyncAction
    let shareApp: AsyncAction
    let writeReview: AsyncAction
    let contactUs: AsyncAction
    let navigateToDiagnotics: AsyncAction
    let refreshAuthenticationState: AsyncAction
    let loginAction: AsyncAction
    let logoutAction: AsyncAction

    var body: some View {
        NoorList {
            NoorBasicSection {
                VStack {
                    AppearanceModeSelector(appearanceMode: $appearanceMode)
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

            #if QURAN_SYNC
                // TODO: Pending translations, and hiding if OAuth is not configured.
                NoorBasicSection {
                    if isAuthenticated {
                        NoorListItem(
                            title: .text("Logout from Quran.com"),
                            action: logoutAction
                        )
                    } else {
                        NoorListItem(
                            title: .text("Login with Quran.com"),
                            action: loginAction
                        )
                    }
                }
            #endif

            NoorBasicSection {
                NoorListItem(
                    image: .init(.debug),
                    title: .text(l("diagnostics.title")),
                    accessory: .disclosureIndicator,
                    action: navigateToDiagnotics
                )
            }
        }
        .task { await refreshAuthenticationState() }
        .errorAlert(error: $error)
    }
}

struct SettingsRootView_Previews: PreviewProvider {
    struct Container: View {
        @State var appearanceMode: AppearanceMode

        var body: some View {
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                error: .constant(nil),
                audioEnd: "Surah",
                isAuthenticated: false,
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {},
                refreshAuthenticationState: {},
                loginAction: {},
                logoutAction: {}
            )
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(appearanceMode: .auto)
        }
    }
}
