//
//  NoDataView.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/5/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import SwiftUI
import UIx

public struct NoDataView: View {
    // MARK: Lifecycle

    public init(title: String, text: String, image: String) {
        self.title = title
        self.text = text
        self.image = image
    }

    // MARK: Public

    public var body: some View {
        VStack {
            Image(systemName: image)
                .foregroundColor(.secondaryLabel)
                .font(.title)
            Text(title)
                .foregroundColor(.secondaryLabel)
                .font(.headline)
                .padding()
            Text(text)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: Internal

    let title: String
    let text: String
    let image: String
}

struct NoDataView_Previews: PreviewProvider {
    static var previews: some View {
        NoDataView(
            title: "Adding Bookmarks...",
            text: "When you're reading a book, tap the Bookmark button to mark the current page.",
            image: "bookmark.fill"
        )
    }
}
