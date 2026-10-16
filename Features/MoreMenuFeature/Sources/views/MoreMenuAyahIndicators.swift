#if QURAN_SYNC
//
//  MoreMenuAyahIndicators.swift
//

import Localization
import NoorUI
import QuranText
import SwiftUI

struct MoreMenuAyahIndicators: View {
    @Binding var visibility: AyahIndicatorVisibility

    var body: some View {
        NoorMenuRow(
            title: l("menu.ayahIndicators"),
            items: AyahIndicatorVisibility.allCases,
            selection: $visibility,
            value: visibility.localizedName
        ) { item in
            Text(item.localizedName)
            if let detail = item.localizedDetail {
                Text(detail)
            }
        }
        .padding()
    }
}

extension AyahIndicatorVisibility {
    var localizedName: String {
        switch self {
        case .all:
            return l("menu.ayahIndicators.all")
        case .readingBookmark:
            return l("menu.ayahIndicators.readingBookmark")
        case .none:
            return l("menu.ayahIndicators.none")
        }
    }

    var localizedDetail: String? {
        switch self {
        case .all:
            return l("menu.ayahIndicators.all.detail")
        case .readingBookmark, .none:
            return nil
        }
    }
}

#Preview {
    struct Container: View {
        @State var visibility = AyahIndicatorVisibility.readingBookmark

        var body: some View {
            VStack(spacing: 0) {
                MoreMenuAyahIndicators(visibility: $visibility)
                Divider()
                MoreMenuAyahIndicators(visibility: .constant(.all))
            }
        }
    }
    return Container()
}

#endif
