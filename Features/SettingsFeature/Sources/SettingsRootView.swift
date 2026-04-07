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
            loggedInUserEmail: viewModel.currentUserEmail,
            openQuranComProfile: { viewModel.openQuranComProfile() },
            navigateToAudioEndSelector: { viewModel.navigateToAudioEndSelector() },
            navigateToAudioManager: { viewModel.navigateToAudioManager() },
            navigateToTranslationsList: { viewModel.navigateToTranslationsList() },
            navigateToReadingSelector: { viewModel.navigateToReadingSelectors() },
            donate: { viewModel.donate() },
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
    // MARK: Internal

    @Binding var appearanceMode: AppearanceMode
    @Binding var error: Error?

    let audioEnd: String
    let isAuthenticated: Bool
    let loggedInUserEmail: String?
    let openQuranComProfile: AsyncAction
    let navigateToAudioEndSelector: AsyncAction
    let navigateToAudioManager: AsyncAction
    let navigateToTranslationsList: AsyncAction
    let navigateToReadingSelector: AsyncAction
    let donate: AsyncAction
    let shareApp: AsyncAction
    let writeReview: AsyncAction
    let contactUs: AsyncAction
    let navigateToDiagnotics: AsyncAction
    let refreshAuthenticationState: AsyncAction
    let loginAction: AsyncAction
    let logoutAction: AsyncAction

    var body: some View {
        NoorList {
            #if QURAN_SYNC
                NoorBasicSection {
                    if isAuthenticated {
                        authenticatedQuranComSection
                    } else {
                        unauthenticatedQuranComSection
                    }
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
        .task { await refreshAuthenticationState() }
        .errorAlert(error: $error)
    }

    // MARK: Private

    private var unauthenticatedQuranComSection: some View {
        Group {
            NoorListItem(
                image: .init(.profile, color: .secondaryLabel),
                title: styledText(l("setting.quran_account.sign_in"), fontWeight: .semibold),
                accessory: .disclosureIndicator,
                action: loginAction
            )

            NoorListItem(
                image: .init(.checkmark, color: .accentColor),
                title: .text(l("setting.quran_account.sync_devices"))
            )

            NoorListItem(
                image: .init(.checkmark, color: .accentColor),
                title: .text(l("setting.quran_account.custom_collections"))
            )

            NoorListItem(
                image: .init(.checkmark, color: .accentColor),
                title: .text(l("setting.quran_account.attach_notes"))
            )
        }
    }

    private var authenticatedQuranComSection: some View {
        Group {
            NoorListItem(
                image: .init(.profile, color: .secondaryLabel),
                title: .text(loggedInUserEmail ?? l("setting.quran_account.profile")),
                accessory: .image(.settings, color: .secondaryLabel),
                action: openQuranComProfile
            )

            NoorListItem(
                image: .init(.signOut, color: .secondaryLabel),
                title: styledText(l("setting.quran_account.sign_out"), foregroundColor: .red),
                action: logoutAction
            )
        }
    }

    private func styledText(
        _ text: String,
        foregroundColor: Color? = nil,
        fontWeight: Font.Weight? = nil
    ) -> MultipartText {
        let range = text.startIndex ..< text.endIndex
        return "\(text, highlighting: [HighlightingRange(range, foregroundColor: foregroundColor, fontWeight: fontWeight)])"
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
                loggedInUserEmail: nil,
                openQuranComProfile: {},
                navigateToAudioEndSelector: {},
                navigateToAudioManager: {},
                navigateToTranslationsList: {},
                navigateToReadingSelector: {},
                donate: {},
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
