//
//  SimpleListItem.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx

public struct SimpleListItem: View {
    // MARK: Lifecycle

    public init(
        image: Image? = nil,
        title: String,
        subtitle: String? = nil,
        showDisclosureIndicator: Bool,
        action: AsyncAction? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.showDisclosureIndicator = showDisclosureIndicator
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        if let action {
            Button(asyncAction: action) {
                content
            }
        } else {
            content
        }
    }

    // MARK: Internal

    let image: Image?
    let title: String
    let subtitle: String?
    let showDisclosureIndicator: Bool
    let action: AsyncAction?

    // MARK: Private

    private var content: some View {
        HStack {
            if let image {
                image
            }
            Text(title)

            if subtitle != nil || showDisclosureIndicator {
                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.secondaryLabel)
                }

                if showDisclosureIndicator {
                    DisclosureIndicator()
                }
            }
        }
        .foregroundColor(.primary)
    }
}

struct SimpleListItem_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach(0 ..< 100) { section in
                Section {
                    SimpleListItem(
                        image: NoorSystemImage.audio.image,
                        title: "Title",
                        showDisclosureIndicator: false
                    ) {
                    }

                    SimpleListItem(
                        image: NoorSystemImage.share.image,
                        title: "Title",
                        showDisclosureIndicator: true
                    ) {
                    }

                    SimpleListItem(
                        image: NoorSystemImage.mail.image,
                        title: "Title",
                        subtitle: "Subtitle",
                        showDisclosureIndicator: true
                    ) {
                    }
                } header: {
                    Text("Section \(section + 1)")
                }
            }
        }
    }
}
