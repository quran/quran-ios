//
//  SimpleListItem.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx

public struct SimpleListItem: View {
    public struct Subtitle {
        // MARK: Lifecycle

        public init(text: String, location: SubtitleLocation) {
            self.text = text
            self.location = location
        }

        // MARK: Internal

        let text: String
        let location: SubtitleLocation
    }

    public enum SubtitleLocation {
        case trailing
        case bottom
    }

    public enum Accessory {
        case disclosureIndicator
    }

    // MARK: Lifecycle

    public init(
        image: Image? = nil,
        title: String,
        subtitle: Subtitle? = nil,
        accessory: Accessory? = nil,
        action: AsyncAction? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
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
    let subtitle: Subtitle?
    let accessory: Accessory?
    let action: AsyncAction?

    // MARK: Private

    private var content: some View {
        HStack {
            if let image {
                image
            }

            VStack(alignment: .leading) {
                Text(title)
                if let subtitle, subtitle.location == .bottom {
                    Text(subtitle.text)
                        .foregroundColor(.secondaryLabel)
                        .font(.footnote)
                }
            }

            if subtitle?.location == .trailing || accessory != nil {
                Spacer()

                if let subtitle, subtitle.location == .trailing {
                    Text(subtitle.text)
                        .foregroundColor(.secondaryLabel)
                }

                if let accessory {
                    switch accessory {
                    case .disclosureIndicator:
                        DisclosureIndicator()
                    }
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
                        accessory: .none
                    )

                    SimpleListItem(
                        image: NoorSystemImage.share.image,
                        title: "Title",
                        accessory: .disclosureIndicator
                    ) {
                    }

                    SimpleListItem(
                        image: NoorSystemImage.mail.image,
                        title: "Title",
                        subtitle: .init(text: "Subtitle", location: .trailing),
                        accessory: .disclosureIndicator
                    ) {
                    }

                    SimpleListItem(
                        title: "Reciter name",
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .none
                    ) {
                    }
                } header: {
                    Text("Section \(section + 1)")
                }
            }
        }
    }
}
