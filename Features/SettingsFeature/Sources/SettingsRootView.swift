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
        #if QURAN_SYNC
        SettingsRootViewUI(
            appearanceMode: $viewModel.appearanceMode,
            streamingEnabled: $viewModel.streamingEnabled,
            error: $viewModel.error,
            audioEnd: viewModel.audioEnd.name,
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() },
            isAuthenticated: viewModel.isAuthenticated,
            loggedInUserEmail: viewModel.currentUserEmail,
            openQuranComProfile: { viewModel.openQuranComProfile() },
            refreshAuthenticationState: { await viewModel.refreshAuthenticationState() },
            loginAction: { await viewModel.loginToQuranCom() },
            logoutAction: { await viewModel.logoutFromQuranCom() }
        )
        #else
        SettingsRootViewUI(
            appearanceMode: $viewModel.appearanceMode,
            streamingEnabled: $viewModel.streamingEnabled,
            error: $viewModel.error,
            audioEnd: viewModel.audioEnd.name,
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
            shareApp: { viewModel.shareApp() },
            writeReview: { viewModel.writeReview() },
            contactUs: { viewModel.contactUs() },
            navigateToDiagnotics: { viewModel.navigateToDiagnotics() }
        )
        #endif
    }
}

private struct SettingsRootViewUI: View {
    // MARK: Internal

    @Binding var appearanceMode: AppearanceMode
    @Binding var streamingEnabled: Bool
    @Binding var error: Error?

    let audioEnd: String
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let navigateToReadingSelector: AsyncAction
    let donate: AsyncAction
    let shareApp: AsyncAction
    let writeReview: AsyncAction
    let contactUs: AsyncAction
    let navigateToDiagnotics: AsyncAction

    #if QURAN_SYNC
    let isAuthenticated: Bool
    let loggedInUserEmail: String?
    let openQuranComProfile: AsyncAction
    let refreshAuthenticationState: AsyncAction
    let loginAction: AsyncAction
    let logoutAction: AsyncAction
    #endif

    var body: some View {
        NoorList {
            #if QURAN_SYNC
            NoorBasicSection {
                QuranComAccountCard(
                    isAuthenticated: isAuthenticated,
                    email: loggedInUserEmail,
                    manageAccountAction: { await openQuranComProfile() },
                    signInAction: { await loginAction() },
                    signOutAction: { await logoutAction() }
                )
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
            }
            #endif

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
                    subtitle: .init(text: .text(audioEnd), location: .trailing),
                    accessory: .disclosureIndicator,
                    action: navigateToAudioEndSelector
                )

                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(l("audio.streaming.title"))
                        Text(l("audio.streaming.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(l("audio.streaming.title"), isOn: $streamingEnabled)
                        .labelsHidden()
                }
                .padding(.vertical, 6)

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
                    image: .init(.heart),
                    title: .text(l("setting.donate")),
                    accessory: .disclosureIndicator,
                    action: donate
                )

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
        #if QURAN_SYNC
        .task { await refreshAuthenticationState() }
        #endif
        .errorAlert(error: $error)
    }
}

struct SettingsRootView_Previews: PreviewProvider {
    struct Container: View {
        @State var appearanceMode: AppearanceMode
        @State var streamingEnabled = false

        var body: some View {
            #if QURAN_SYNC
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                streamingEnabled: $streamingEnabled,
                error: .constant(nil),
                audioEnd: "Surah",
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {},
                isAuthenticated: false,
                loggedInUserEmail: nil,
                openQuranComProfile: {},
                refreshAuthenticationState: {},
                loginAction: {},
                logoutAction: {}
            )
            #else
            SettingsRootViewUI(
                appearanceMode: $appearanceMode,
                streamingEnabled: $streamingEnabled,
                error: .constant(nil),
                audioEnd: "Surah",
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
                shareApp: {},
                writeReview: {},
                contactUs: {},
                navigateToDiagnotics: {}
            )
            #endif
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(appearanceMode: .auto)
        }
    }
}
