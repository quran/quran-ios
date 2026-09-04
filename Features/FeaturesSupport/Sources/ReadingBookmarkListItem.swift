#if QURAN_SYNC
//
//  ReadingBookmarkListItem.swift
//

import Foundation
import Localization
import NoorUI
import QuranAnnotations
import QuranTextKit
import SwiftUI
import UIx

public struct ReadingBookmarkListItem: View {
    // MARK: Lifecycle

    public init(
        bookmark: PlacedReadingBookmark,
        action: @escaping Action
    ) {
        self.bookmark = bookmark
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        NoorListItem(
            image: .init(
                Image(uiImage: ReadingBookmarkPin.image(style: .filled)),
                color: bookmark.slot.swiftUIColor
            ),
            title: "\(bookmark.slot.displayName) · \(sura: bookmark.sura)",
            subtitle: .init(
                text: "\(locationTitle) · \(bookmark.modifiedOn.timeAgo())",
                location: .bottom
            ),
            accessory: .disclosureIndicator,
            action: .sync { action() }
        )
    }

    // MARK: Private

    private let bookmark: PlacedReadingBookmark
    private let action: Action

    private var locationTitle: String {
        switch bookmark.placement {
        case .ayah(let ayah):
            lFormat("quran_ayah", table: .android, ayah.ayah)
        case .page(let page):
            "\(lAndroid("quran_page")) \(NumberFormatter.shared.format(page.pageNumber))"
        }
    }
}
#endif
