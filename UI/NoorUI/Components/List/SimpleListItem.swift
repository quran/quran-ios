//
//  SimpleListItem.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx

public struct SimpleListItem: View {
    public enum Title {
        case text(String)
        case sura(name: String, arabic: String)
    }

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

    public struct ItemImage {
        // MARK: Lifecycle

        public init(_ image: NoorSystemImage, color: Color? = nil) {
            self.image = image
            self.color = color
        }

        // MARK: Internal

        let image: NoorSystemImage
        let color: Color?
    }

    public enum Accessory {
        case text(String)
        case disclosureIndicator
        case download(DownloadType, action: AsyncAction)

        // MARK: Internal

        var actionable: Bool {
            switch self {
            case .text: return false
            case .download: return true
            case .disclosureIndicator: return false
            }
        }
    }

    // MARK: Lifecycle

    public init(
        image: ItemImage? = nil,
        heading: String? = nil,
        title: Title,
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
                content
                    .onTapGesture(asyncAction: action)
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

    let image: ItemImage?
    let heading: String?
    let title: Title
    let subtitle: Subtitle?
    let accessory: Accessory?
    let action: AsyncAction?

    // MARK: Private

    private var content: some View {
        HStack {
            if let image {
                if let color = image.color {
                    image.image.image
                        .foregroundColor(color)
                } else {
                    image.image.image
                }
            }

            VStack(alignment: .leading) {
                if let heading {
                    Text(heading)
                        .foregroundColor(.accentColor)
                }

                titleView

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
                    case .text(let text):
                        Text(text)
                            .foregroundColor(.secondaryLabel)
                            .fontWeight(.light)
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
    private var titleView: some View {
        switch title {
        case .text(let text):
            Text(text)
        case .sura(let name, let arabic):
            HStack {
                Text(name)
                if NSLocale.preferredLanguages.first != "ar" {
                    Text(arabic)
                        .padding(.top, 5)
                        .frame(alignment: .center)
                        .font(.custom(.suraNames, size: 20))
                }
            }
        }
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
                        image: .init(.audio),
                        title: .text("Title"),
                        accessory: .none
                    )

                    SimpleListItem(
                        image: .init(.share),
                        heading: "English",
                        title: .text("An English title"),
                        subtitle: .init(label: "Translator: ", text: "An English subtitle", location: .bottom)
                    ) {
                    }

                    SimpleListItem(
                        image: .init(.mail),
                        title: .text("Title"),
                        subtitle: .init(text: "Subtitle", location: .trailing),
                        accessory: .disclosureIndicator
                    ) {
                    }

                    SimpleListItem(
                        title: .text("Reciter name"),
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .none
                    ) {
                    }

                    SimpleListItem(
                        image: .init(.bookmark, color: .red),
                        title: .sura(name: "Sura 1", arabic: String(UnicodeScalar(0xE907)!)),
                        subtitle: .init(text: "Just now", location: .bottom),
                        accessory: .text("44")
                    ) {
                    }

                    SimpleListItem(
                        title: .text("Reciter name"),
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .download(.downloading(progress: 0.9), action: {})
                    ) {
                    }

                    SimpleListItem(
                        title: .text("Reciter name"),
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
