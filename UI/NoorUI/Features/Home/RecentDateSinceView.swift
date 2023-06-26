//
//  RecentDateSinceView.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx

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

struct RecentDateSinceView_Previews: PreviewProvider {
    static var previews: some View {
        Previewing.list {
            RecentDateSinceView(since: "23 hours ago")
                .padding()
            Divider()
                .padding(.leading)
        }
    }
}
