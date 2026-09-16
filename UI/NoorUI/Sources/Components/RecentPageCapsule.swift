import NoorFont
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
                    MultipartText("\(sura: page.firstVerse.sura, nameStyle: .compact)")
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
        .accessibilityLabel("\(page.firstVerse.sura.localizedName()), \(page.localizedName), \(timestamp)")
    }
}

#Preview("English") {
    let _ = {
        if UIFont(name: "icomoon", size: 20) == nil {
            FontName.registerFonts()
        }
    }()

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
