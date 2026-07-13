#if QURAN_SYNC
//
//  BookmarkCollectionsLandingView.swift
//

import Localization
import NoorUI
import SwiftUI
import UIx

@MainActor
struct BookmarkCollectionsLandingView: View {
    @StateObject var viewModel: BookmarkCollectionsLandingViewModel

    init(viewModel: BookmarkCollectionsLandingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NoorList {
            if viewModel.shouldShowSyncBanner {
                NoorBasicSection {
                    BookmarkCollectionsSyncBanner(
                        dismiss: { viewModel.dismissSyncBanner() },
                        signInAction: { await viewModel.loginToQuranCom() }
                    )
                }
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.bookmark, color: .secondary),
                    title: .text(l("bookmarks.old-page-bookmarks")),
                    subtitle: .init(
                        text: NumberFormatter.shared.format(viewModel.oldPageBookmarksCount),
                        location: .trailing
                    ),
                    accessory: .disclosureIndicator,
                    action: { viewModel.showOldPageBookmarks() }
                )
            }

            NoorBasicSection {
                NoorListItem(
                    image: .init(.folder, color: .accentColor),
                    title: .text(l("bookmarks.collections")),
                    accessory: .disclosureIndicator,
                    action: { viewModel.showCollections() }
                )
            }
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
    }
}

@MainActor
private struct BookmarkCollectionsSyncBanner: View {
    @ScaledMetric private var closeButtonInset = 8.0
    @ScaledMetric private var containerCornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var containerPadding = 16.0
    @ScaledMetric private var contentSpacing = 12.0
    @ScaledMetric private var titleSpacing = 4.0
    @ScaledMetric private var trailingSpacing = 8.0

    let dismiss: () -> Void
    let signInAction: @MainActor () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(alignment: .top, spacing: contentSpacing) {
                NoorSystemImage.bookmark.image
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: titleSpacing) {
                    Text(l("bookmarks.sync.title"))
                        .font(.headline)

                    Text(l("bookmarks.sync.body"))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: trailingSpacing)

                Button(action: dismiss) {
                    NoorSystemImage.cancel.image
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.secondaryLabel)
                        .padding(closeButtonInset)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lAndroid("cancel"))
            }

            ProminentRoundedButton(label: l("bookmarks.sync.action")) {
                await signInAction()
            }
        }
        .padding(containerPadding)
        .background(Color.secondarySystemBackground)
        .overlay(
            RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        )
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
    }
}
#endif
