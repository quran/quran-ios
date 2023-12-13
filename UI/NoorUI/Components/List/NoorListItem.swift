//
//  NoorListItem.swift
//
//
//  Created by Mohamed Afifi on 2023-06-25.
//

import SwiftUI
import UIx
import VLogging

public struct NoorListItem: View {
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
        case image(NoorSystemImage, color: Color? = nil)

        // MARK: Internal

        var actionable: Bool {
            switch self {
            case .text: return false
            case .download: return true
            case .disclosureIndicator: return false
            case .image: return false
            }
        }
    }

    // MARK: Lifecycle

    public init(
        leadingEdgeLineColor: Color? = nil,
        image: ItemImage? = nil,
        heading: String? = nil,
        subheading: MultipartText? = nil,
        rightPretitle: MultipartText? = nil,
        title: MultipartText,
        rightSubtitle: MultipartText? = nil,
        subtitle: Subtitle? = nil,
        accessory: Accessory? = nil,
        action: AsyncAction? = nil
    ) {
        self.leadingEdgeLineColor = leadingEdgeLineColor
        self.image = image
        self.heading = heading
        self.subheading = subheading
        self.rightPretitle = rightPretitle
        self.title = title
        self.rightSubtitle = rightSubtitle
        self.subtitle = subtitle
        self.accessory = accessory
        _action = action
    }

    // MARK: Public

    public var body: some View {
        if let action {
            if let accessory, accessory.actionable {
                // Use Tap gesture since tapping accessory button will also trigger the whole cell selection.
                content
                    .onAsyncTapGesture(asyncAction: action)
            } else {
                AsyncButton(action: action) {
                    content
                }
            }
        } else {
            content
        }
    }

    // MARK: Internal

    let leadingEdgeLineColor: Color?
    let image: ItemImage?
    let heading: String?
    let subheading: MultipartText?
    let rightPretitle: MultipartText?
    let title: MultipartText
    let rightSubtitle: MultipartText?
    let subtitle: Subtitle?
    let accessory: Accessory?
    let _action: AsyncAction?

    // MARK: Private

    private var action: AsyncAction? {
        guard let _action else {
            return nil
        }
        return {
            let properties: [(String, String?)] = [
                ("heading", heading),
                ("subheading", subheading?.rawValue),
                ("rightPretitle", rightPretitle?.rawValue),
                ("title", title.rawValue),
                ("rightSubtitle", rightSubtitle?.rawValue),
                ("subtitle", subtitle?.label),
            ]
            let description = properties.compactMap { p in p.1.map { "\(p.0)=\($0)" } }.joined()
            logger.info("NoorListItem tapped. {\(description)}")
            await _action()
        }
    }

    private var content: some View {
        HStack {
            if let leadingEdgeLineColor {
                leadingEdgeLineColor
                    .frame(width: 4)
            }

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

                if let subheading {
                    subheading.view(ofSize: .caption)
                        .foregroundColor(Color.secondaryLabel)
                }

                if let rightPretitle {
                    HStack {
                        rightPretitle.view(ofSize: .body)
                        Spacer()
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }

                title.view(ofSize: .body)

                if let rightSubtitle {
                    HStack {
                        rightSubtitle.view(ofSize: .caption)
                            .foregroundColor(.secondaryLabel)
                        Spacer()
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }

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
                    case let .image(image, color):
                        if let color {
                            image.image
                                .foregroundColor(color)
                        } else {
                            image.image
                        }
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

struct NoorListItem_Previews: PreviewProvider {
    static let ayahText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"

    static var previews: some View {
        List {
            ForEach(0 ..< 100) { section in
                Section {
                    NoorListItem(
                        image: .init(.audio),
                        title: "Title",
                        accessory: .none
                    )

                    NoorListItem(
                        image: .init(.share),
                        heading: "English",
                        title: "An English title",
                        subtitle: .init(label: "Translator: ", text: "An English subtitle", location: .bottom)
                    ) {
                    }

                    NoorListItem(
                        leadingEdgeLineColor: .purple,
                        subheading: "Sura 1, verse 2 \(sura: String(UnicodeScalar(0xE907)!))",
                        rightPretitle: "\(verse: ayahText, color: .purple, lineLimit: 2)",
                        title: "An English title",
                        subtitle: .init(text: "6 days ago", location: .bottom)
                    ) {
                    }

                    NoorListItem(
                        image: .init(.mail),
                        title: "Title",
                        subtitle: .init(text: "Subtitle", location: .trailing),
                        accessory: .disclosureIndicator
                    ) {
                    }

                    NoorListItem(
                        title: "Reciter name",
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .none
                    ) {
                    }

                    NoorListItem(
                        image: .init(.bookmark, color: .red),
                        title: "Sura 1 \(sura: String(UnicodeScalar(0xE907)!))",
                        subtitle: .init(text: "Just now", location: .bottom),
                        accessory: .text("44")
                    ) {
                    }

                    NoorListItem(
                        title: "Reciter name",
                        subtitle: .init(text: "1.25GB – 14 suras downloaded", location: .bottom),
                        accessory: .download(.downloading(progress: 0.9), action: {})
                    ) {
                    }

                    NoorListItem(
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
