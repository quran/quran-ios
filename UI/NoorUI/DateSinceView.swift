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
    public init(since: String) {
        self.since = since
    }

    let since: String

    public var body: some View {
        Text(since)
            .foregroundColor(.secondaryLabel)
            .font(.footnote)
    }
}

private struct DateSinceView<Image: View>: View {
    public init(since: String, image: @escaping () -> Image) {
        self.since = since
        self.image = image
    }

    let since: String
    let image: () -> Image

    public var body: some View {
        HStack {
            image()
                .font(.footnote)
            DateSinceTextView(since: since)
            Spacer()
        }
    }
}

public struct BookmarkDateSinceView: View {
    public init(since: String) {
        self.since = since
    }

    let since: String

    public var body: some View {
        DateSinceView(since: since) {
            Image(systemName: "bookmark.fill")
                .foregroundColor(.red)
        }
    }
}

public struct RecentDateSinceView: View {
    public init(since: String) {
        self.since = since
    }

    let since: String

    public var body: some View {
        DateSinceView(since: since) {
            Image(systemName: "clock")
                .foregroundColor(.secondaryLabel)
        }
    }
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
