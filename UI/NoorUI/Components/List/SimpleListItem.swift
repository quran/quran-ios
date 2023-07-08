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

        public init(label: String? = nil, text: String, location: SubtitleLocation) {
            self.label = label
            self.text = text
            self.location = location
        }

        // MARK: Internal

        let label: String?
        let text: String
        let location: SubtitleLocation
    }

    public enum SubtitleLocation {
        case trailing
        case bottom
    }

    public enum Accessory {
        case disclosureIndicator
        case download(DownloadType, action: AsyncAction)

        // MARK: Internal

        var actionable: Bool {
            switch self {
            case .download: return true
            case .disclosureIndicator: return false
            }
        }
    }

    // MARK: Lifecycle

    public init(
        image: Image? = nil,
        heading: String? = nil,
        title: String,
        subtitle: Subtitle? = nil,
        accessory: Accessory? = nil,
        action: AsyncAction? = nil
    ) {
        self.image = image
        self.heading = heading
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        if let action {
            if let accessory, accessory.actionable {
                // Use Tap gesture since tapping accessory button will also trigger the whole cell selection.
                content.onTapGesture {
                    Task {
                        await action()
                    }
                }
            } else {
                Button(asyncAction: action) {
                    content
                }
            }
        } else {
            content
        }
    }

    // MARK: Internal

    let image: Image?
    let heading: String?
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
                if let heading {
                    Text(heading)
                        .foregroundColor(.accentColor)
                }

                Text(title)
                if let subtitle, subtitle.location == .bottom {
                    subtitleView(subtitle, textFont: .footnote)
                }
            }

            if subtitle?.location == .trailing || accessory != nil {
                Spacer()

                if let subtitle, subtitle.location == .trailing {
                    subtitleView(subtitle, textFont: .body)
                }

                if let accessory {
                    switch accessory {
                    case .disclosureIndicator:
                        DisclosureIndicator()
                    case let .download(type, action):
                        AppStoreDownloadButton(type: type, action: action)
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func subtitleText(_ subtitle: Subtitle, textFont: Font) -> Text {
        Text(subtitle.text)
            .foregroundColor(.secondaryLabel)
            .font(textFont)
    }

    @ViewBuilder
    private func subtitleView(_ subtitle: Subtitle, textFont: Font) -> some View {
        if let label = subtitle.label {
            Text(label)
                .foregroundColor(.secondaryLabel)
                .font(textFont.bold()) +
                subtitleText(subtitle, textFont: textFont)
        } else {
            subtitleText(subtitle, textFont: textFont)
        }
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
                        heading: "English",
                        title: "An English title",
                        subtitle: .init(label: "Translator: ", text: "An English subtitle", location: .bottom)
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

                    SimpleListItem(
                        title: "Reciter name",
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .download(.downloading(progress: 0.9), action: {})
                    ) {
                    }

                    SimpleListItem(
                        title: "Reciter name",
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .download(.download, action: {})
                    )

                } header: {
                    Text("Section \(section + 1)")
                }
            }
        }
    }
}
