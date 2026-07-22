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
        bookmark: ReadingPositionBookmark,
        action: @escaping AsyncAction
    ) {
        self.bookmark = bookmark
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        NoorListItem(
            image: .init(
                Image(uiImage: ReadingBookmarkPin.image(style: .filled)),
                color: .red
            ),
            title: "\(sura: bookmark.sura)",
            subtitle: .init(
                text: "\(locationTitle) · \(bookmark.modifiedOn.timeAgo())",
                location: .bottom
            ),
            accessory: .disclosureIndicator,
            action: action
        )
    }

    // MARK: Private

    private let bookmark: ReadingPositionBookmark
    private let action: AsyncAction

    private var locationTitle: String {
        switch bookmark.location {
        case .ayah(let ayah):
            lFormat("quran_ayah", table: .android, ayah.ayah)
        case .page(let page):
            "\(lAndroid("quran_page")) \(NumberFormatter.shared.format(page.pageNumber))"
        }
    }
}
#endif
