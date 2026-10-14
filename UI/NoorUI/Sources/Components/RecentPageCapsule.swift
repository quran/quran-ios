import Localization
import QuranKit
import QuranLocalization
import SwiftUI

@MainActor
struct RecentPageCapsule: View {
    let page: Page
    let timestamp: String
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var badgeSize = 36
    @ScaledMetric private var spacing = 8
    @ScaledMetric private var inset = 8

    var body: some View {
        Button(action: action) {
            HStack {
                Text(page.localizedNumber)
                    .font(.subheadline.weight(.semibold))
                    .frame(minWidth: badgeSize, minHeight: badgeSize)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    suraNames
                        .view(ofSize: .subheadline, allowsWrapping: false)
                    Text(timestamp)
                        .font(.caption)
                        .foregroundColor(.secondaryLabel)
                }
            }
            .padding(inset)
            .padding(.trailing, spacing)
            .background(Color(uiColor: .tertiarySystemGroupedBackground), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    /// Sura names, page and timestamp as a spoken list. The sura names read as one item, and the timestamp can be
    /// a date with commas.
    var accessibilityLabel: String {
        [suraNames.accessibilityText, page.localizedName, timestamp].joined(separator: l("list.separator"))
    }

    private var suraNames: MultipartText {
        "\(suras: page.suras)"
    }
}

#Preview("English") {
    List {
        Section {
            RecentPageCapsule(page: Quran.hafsMadani1405.pages[0], timestamp: "1 min ago", action: {})
        }
        .environment(\.locale, Locale(identifier: "en"))

        Section {
            RecentPageCapsule(page: Quran.hafsMadani1405.pages[0], timestamp: "قبل دقيقة", action: {})
        }
        .environment(\.locale, Locale(identifier: "ar"))
        .environment(\.layoutDirection, .rightToLeft)

        Section {
            RecentPageCapsule(page: Quran.hafsMadani1405.suras[62].page, timestamp: "32 min ago", action: {})
        }
        .environment(\.locale, Locale(identifier: "en"))

        Section {
            ScrollView(.horizontal) {
                RecentPageCapsule(page: Quran.hafsMadani1405.suras[62].page, timestamp: "32 min ago", action: {})
            }
        }
        .environment(\.dynamicTypeSize, .accessibility3)
        .environment(\.locale, Locale(identifier: "en"))
    }
}
