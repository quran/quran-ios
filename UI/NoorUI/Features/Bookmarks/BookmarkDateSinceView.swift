//
//  BookmarkDateSinceView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx

struct BookmarkDateSinceView: View {
    let since: String

    var body: some View {
        DateSinceView(since: since) {
            Image(systemName: "bookmark.fill")
                .foregroundColor(.red)
        }
    }
}

struct BookmarkDateSinceView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.list {
            BookmarkDateSinceView(since: "21 minutes ago")
                .padding()
            Divider()
                .padding(.leading)
        }
    }
}
