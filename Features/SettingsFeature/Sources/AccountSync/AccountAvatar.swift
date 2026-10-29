#if QURAN_SYNC
//
//  AccountAvatar.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import NoorUI
import SwiftUI

/// The signed-in user's photo, or their initials in a tinted circle while it loads or when there's none.
struct AccountAvatar: View {
    // MARK: Internal

    let profile: AccountProfile
    let length: CGFloat

    var body: some View {
        Group {
            if let photoURL = profile.photoURL {
                AsyncImage(url: photoURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: length, height: length)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }

    // MARK: Private

    private var initials: some View {
        Group {
            if profile.initials.isEmpty {
                NoorSystemImage.profile.image
                    .font(.system(size: length * 0.45, weight: .semibold))
            } else {
                Text(profile.initials)
                    .font(.system(size: length * 0.38, weight: .semibold))
            }
        }
        .foregroundStyle(Color.accentColor)
        .frame(width: length, height: length)
        .background(Color.accentColor.opacity(0.1))
    }
}
#endif
