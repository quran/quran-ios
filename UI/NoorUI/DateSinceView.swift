//
//  BookmarkDateSinceView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/27/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct DateSinceTextView: View {
    // MARK: Lifecycle

    public init(since: String) {
        self.since = since
    }

    // MARK: Public

    public var body: some View {
        Text(since)
            .foregroundColor(.secondaryLabel)
            .font(.footnote)
    }

    // MARK: Internal

    let since: String
}

private struct DateSinceView<Image: View>: View {
    // MARK: Lifecycle

    public init(since: String, image: @escaping () -> Image) {
        self.since = since
        self.image = image
    }

    // MARK: Public

    public var body: some View {
        HStack {
            image()
                .font(.footnote)
            DateSinceTextView(since: since)
            Spacer()
        }
    }

    // MARK: Internal

    let since: String
    let image: () -> Image
}

public struct BookmarkDateSinceView: View {
    // MARK: Lifecycle

    public init(since: String) {
        self.since = since
    }

    // MARK: Public

    public var body: some View {
        DateSinceView(since: since) {
            Image(systemName: "bookmark.fill")
                .foregroundColor(.red)
        }
    }

    // MARK: Internal

    let since: String
}

public struct RecentDateSinceView: View {
    // MARK: Lifecycle

    public init(since: String) {
        self.since = since
    }

    // MARK: Public

    public var body: some View {
        DateSinceView(since: since) {
            Image(systemName: "clock")
                .foregroundColor(.secondaryLabel)
        }
    }

    // MARK: Internal

    let since: String
}

struct DateSinceView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.list {
            BookmarkDateSinceView(since: "21 minutes ago")
                .padding()
            Divider()

            RecentDateSinceView(since: "23 hours ago")
                .padding()
            Divider()
        }
    }
}
