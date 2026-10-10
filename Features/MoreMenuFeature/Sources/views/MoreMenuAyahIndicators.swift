#if QURAN_SYNC
//
//  MoreMenuAyahIndicators.swift
//

import Localization
import NoorUI
import QuranText
import SwiftUI

struct MoreMenuAyahIndicators: View {
    @Binding var indicators: AyahIndicators

    var body: some View {
        NoorMenuRow(
            title: l("menu.ayahIndicators"),
            items: AyahIndicators.allCases,
            selection: $indicators,
            value: indicators.localizedName
        ) { item in
            Text(item.localizedName)
            if let detail = item.localizedDetail {
                Text(detail)
            }
        }
        .padding()
    }
}

extension AyahIndicators {
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
        @State var indicators = AyahIndicators.readingBookmark

        var body: some View {
            VStack(spacing: 0) {
                MoreMenuAyahIndicators(indicators: $indicators)
                Divider()
                MoreMenuAyahIndicators(indicators: .constant(.all))
            }
        }
    }
    return Container()
}

#endif
