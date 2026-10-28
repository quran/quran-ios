#if QURAN_SYNC
//
//  AccountAvatar.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import NoorUI
import SwiftUI

/// The signed-in user's initials in a tinted circle.
struct AccountAvatar: View {
    let profile: AccountProfile
    let length: CGFloat

    var body: some View {
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
        .background(Color.accentColor.opacity(0.1), in: Circle())
        .accessibilityHidden(true)
    }
}
#endif
