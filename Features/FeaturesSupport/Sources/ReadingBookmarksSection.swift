#if QURAN_SYNC
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
public struct ReadingBookmarksSection: View {
    public init(bookmarks: [PlacedReadingBookmark], selectBookmark: @escaping ItemAction<PlacedReadingBookmark>) {
        self.bookmarks = bookmarks
        self.selectBookmark = selectBookmark
    }

    private let bookmarks: [PlacedReadingBookmark]
    private let selectBookmark: ItemAction<PlacedReadingBookmark>

    @State private var isExpanded = false
    @ScaledMetric(relativeTo: .body) private var minimumButtonHeight = 44

    private var sortedBookmarks: [PlacedReadingBookmark] {
        bookmarks.sorted { $0.modifiedOn > $1.modifiedOn }
    }

    public var body: some View {
        if !bookmarks.isEmpty {
            NoorBasicSection(title: l("ayah.menu.reading-bookmark.title")) {
                ForEach(isExpanded ? sortedBookmarks : Array(sortedBookmarks.prefix(1)), id: \.slot) { bookmark in
                    ReadingBookmarkListItem(
                        bookmark: bookmark,
                        showsBookmarkName: false,
                        action: { selectBookmark(bookmark) }
                    )
                }

                if bookmarks.count > 1 {
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack {
                            Text(isExpanded
                                ? l("reading-bookmarks.show-less")
                                : lFormat("reading-bookmarks.show-more", NumberFormatter.shared.format(bookmarks.count - 1)))
                            Image(systemName: "chevron.down")
                                .font(.footnote.weight(.semibold))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: minimumButtonHeight)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .accessibilityIdentifier("reading-bookmarks-expand")
                }
            }
        }
    }
}

#Preview {
    NoorList {
        ReadingBookmarksSection(
            bookmarks: ReadingBookmarkSlot.allCases.enumerated().map { index, slot in
                PlacedReadingBookmark(
                    id: "preview-\(index)",
                    slot: slot,
                    placement: .page(Quran.hafsMadani1405.pages[index]),
                    modifiedOn: Date(timeIntervalSinceNow: Double(index) * -3600)
                )
            },
            selectBookmark: { _ in }
        )
    }
}
#endif
