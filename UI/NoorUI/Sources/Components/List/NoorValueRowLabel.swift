//
//  NoorValueRowLabel.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI

/// A list row's leading icon, title, and trailing value.
///
/// At accessibility sizes, a title and a trailing value can't share one line
/// without breaking words mid-word, so the value moves under the title.
struct NoorValueRowLabel<Value: View>: View {
    // MARK: Lifecycle

    init(title: String, image: NoorSystemImage?, @ViewBuilder value: () -> Value) {
        self.title = title
        self.image = image
        self.value = value()
    }

    // MARK: Internal

    var body: some View {
        // Menu and button labels can take the tint; keep the title neutral like its neighbors.
        // `NoorListIcon` restores the tint on the icon.
        HStack {
            if let image {
                NoorListIcon {
                    image.image
                }
            }
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading) {
                    Text(title)
                    value
                }
                Spacer()
            } else {
                Text(title)
                Spacer()
                value
            }
        }
        .foregroundColor(.primary)
    }

    // MARK: Private

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let title: String
    private let image: NoorSystemImage?
    private let value: Value
}
