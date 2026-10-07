//
//  StorageFullView.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import Localization
import NoorUI
import SwiftUI
import UIx

/// Shown instead of the app when launch can't open the stores because the device is out of storage.
struct StorageFullView: View {
    // MARK: Internal

    let retry: AsyncAction

    var body: some View {
        GeometryReader { proxy in
            // Scrolls when large text doesn't fit.
            ScrollView {
                VStack {
                    NoorSystemImage.storageFull.image
                        .font(.largeTitle)
                        .imageScale(.large)
                        .foregroundColor(.secondaryLabel)
                        .accessibilityHidden(true)

                    Text(l("error.storage-full.title"))
                        .font(.headline)
                        .foregroundColor(.label)
                        .padding()
                        .accessibilityAddTraits(.isHeader)

                    Text(l("error.storage-full.message"))
                        .foregroundColor(.secondaryLabel)
                        .padding(.bottom)

                    ProminentRoundedButton(label: lAndroid("download_retry"), action: retry)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: maxContentWidth)
                .padding()
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .background(Color.systemBackground.ignoresSafeArea())
    }

    // MARK: Private

    @ScaledMetric private var maxContentWidth = 400.0
}

#Preview {
    StorageFullView(retry: {})
}
