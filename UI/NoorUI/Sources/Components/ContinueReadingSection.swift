import Localization
import QuranAnnotations
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

@MainActor
public struct ContinueReadingSection: View {
    #if QURAN_SYNC
    public init(
        readingBookmarks: [PlacedReadingBookmark],
        lastPages: [LastPage],
        selectReadingBookmark: @escaping (PlacedReadingBookmark) -> Void,
        selectLastPage: @escaping (LastPage) -> Void
    ) {
        self.readingBookmarks = readingBookmarks
        self.lastPages = lastPages
        self.selectReadingBookmark = selectReadingBookmark
        self.selectLastPage = selectLastPage
    }
    #else
    public init(lastPages: [LastPage], selectLastPage: @escaping (LastPage) -> Void) {
        self.lastPages = lastPages
        self.selectLastPage = selectLastPage
    }
    #endif

    #if QURAN_SYNC
    private let readingBookmarks: [PlacedReadingBookmark]
    #endif
    private let lastPages: [LastPage]
    #if QURAN_SYNC
    private let selectReadingBookmark: (PlacedReadingBookmark) -> Void
    #endif
    private let selectLastPage: (LastPage) -> Void

    @State private var bookmarksExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var spacing = 8
    @ScaledMetric private var dotSize = 12
    @ScaledMetric private var minimumButtonHeight = 44

    public var body: some View {
        if hasContent {
            Section {
                #if QURAN_SYNC
                bookmarks
                #endif
                if !lastPages.isEmpty {
                    recentPages
                        .overlay(alignment: .top) {
                            #if QURAN_SYNC
                            if !readingBookmarks.isEmpty {
                                Divider().padding(.horizontal)
                            }
                            #endif
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
            } header: {
                Text("Continue reading")
                    .font(.headline)
                    .foregroundColor(.secondaryLabel)
            }
            .buttonStyle(.plain)
            .textCase(nil)
        }
    }

    private var hasContent: Bool {
        #if QURAN_SYNC
        !readingBookmarks.isEmpty || !lastPages.isEmpty
        #else
        !lastPages.isEmpty
        #endif
    }

    #if QURAN_SYNC
    @ViewBuilder
    private var bookmarks: some View {
        ForEach(Array(readingBookmarks.prefix(bookmarksExpanded ? readingBookmarks.count : 1)), id: \.slot) { bookmark in
            ContinueReadingBookmarkRow(bookmark: bookmark) {
                selectReadingBookmark(bookmark)
            }
        }
        if readingBookmarks.count > 1 {
            Button {
                withAnimation(reduceMotion ? nil : NoorAnimation.standard) {
                    bookmarksExpanded.toggle()
                }
            } label: {
                HStack {
                    if bookmarksExpanded {
                        Spacer(minLength: 0)
                        Text("Show less")
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.semibold))
                        Spacer(minLength: 0)
                    } else {
                        HStack(spacing: -spacing / 2) {
                            ForEach(Array(readingBookmarks.dropFirst()), id: \.slot) { bookmark in
                                Circle()
                                    .fill(bookmark.slot.swiftUIColor)
                                    .frame(width: dotSize, height: dotSize)
                                    .overlay(Circle().stroke(Color(uiColor: .secondarySystemGroupedBackground), lineWidth: 2))
                            }
                        }
                        Text(readingBookmarks.count == 2 ? "1 more bookmark" : "\(readingBookmarks.count - 1) more bookmarks")
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondaryLabel)
                .padding(.horizontal)
                .minimumTouchTarget()
                .animation(nil, value: bookmarksExpanded)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden, edges: .bottom)
            .accessibilityIdentifier("home.readingBookmarks.expand")
            .accessibilityValue(bookmarksExpanded ? "Expanded" : "Collapsed")
        }
    }
    #endif

    private var recentPages: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "clock")
                    .accessibilityHidden(true)
                Text("\(lAndroid("recent_pages")) (\(lastPages.count.formatted()))")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.secondaryLabel)
            .padding(.horizontal)
            .accessibilityElement(children: .combine)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(lastPages) { lastPage in
                        RecentPageCapsule(page: lastPage.page, timestamp: lastPage.modifiedOn.timeAgo()) {
                            selectLastPage(lastPage)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Previews

@MainActor
private struct ContinueReadingSectionPreview: View {
    var bookmarkCount = 3
    var showsRecentPages = true

    var body: some View {
        #if QURAN_SYNC
        ContinueReadingSection(
            readingBookmarks: Array(Self.bookmarks.prefix(bookmarkCount)),
            lastPages: showsRecentPages ? Self.lastPages : [],
            selectReadingBookmark: { _ in },
            selectLastPage: { _ in }
        )
        #else
        ContinueReadingSection(
            lastPages: showsRecentPages ? Self.lastPages : [],
            selectLastPage: { _ in }
        )
        #endif
    }

    private static let referenceDate = Date()
    private static let lastPages: [LastPage] = [0, 4, 49].enumerated().map { index, pageIndex in
        let page = Quran.hafsMadani1405.pages[pageIndex]
        let timestamp = referenceDate.addingTimeInterval(-Double(index * 31 + 1) * 60)
        #if QURAN_SYNC
        return LastPage(id: "preview-\(pageIndex)", page: page, modifiedOn: timestamp)
        #else
        return LastPage(page: page, createdOn: timestamp, modifiedOn: timestamp)
        #endif
    }

    #if QURAN_SYNC
    private static let bookmarks: [PlacedReadingBookmark] = [
        PlacedReadingBookmark(
            id: "preview-teal", slot: .teal,
            placement: .ayah(Quran.hafsMadani1405.suras[0].verses[5]),
            modifiedOn: referenceDate.addingTimeInterval(-36000)
        ),
        PlacedReadingBookmark(
            id: "preview-coral", slot: .coral,
            placement: .page(Quran.hafsMadani1405.pages[22]),
            modifiedOn: referenceDate.addingTimeInterval(-86400)
        ),
        PlacedReadingBookmark(
            id: "preview-indigo", slot: .indigo,
            placement: .ayah(Quran.hafsMadani1405.suras[35].verses[57]),
            modifiedOn: referenceDate.addingTimeInterval(-259_200)
        ),
    ]
    #endif
}

#Preview {
    List {
        #if QURAN_SYNC
        ContinueReadingSectionPreview()

        ContinueReadingSectionPreview(bookmarkCount: 1)

        ContinueReadingSectionPreview(showsRecentPages: false)
        #endif

        ContinueReadingSectionPreview(bookmarkCount: 0)
    }
}
