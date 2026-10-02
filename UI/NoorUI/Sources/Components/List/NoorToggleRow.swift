//
//  NoorToggleRow.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI

/// A list row with a leading icon, a title, and a trailing switch.
///
/// The icon takes the app tint and the title stays primary, like the other Noor rows.
/// VoiceOver reads the row as one switch named by its title.
public struct NoorToggleRow: View {
    // MARK: Lifecycle

    public init(title: String, image: NoorSystemImage? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.image = image
        _isOn = isOn
    }

    // MARK: Public

    public var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                if let image {
                    NoorListIcon {
                        image.image
                    }
                    .accessibilityHidden(true)
                }
                Text(title)
                    .foregroundColor(.primary)
            }
        }
    }

    // MARK: Private

    @Binding private var isOn: Bool

    private let title: String
    private let image: NoorSystemImage?
}

#Preview {
    struct Container: View {
        @State var isOn = false

        var body: some View {
            NoorList {
                NoorBasicSection(footer: "Streaming saves space but needs an internet connection.") {
                    NoorMenuRow(
                        title: "Playback Speed",
                        image: .playbackSpeed,
                        items: [0.5, 1, 1.5],
                        selection: .constant(1),
                        label: { "\($0)×" }
                    )
                    NoorToggleRow(title: "Stream Audio", image: .stream, isOn: $isOn)
                }
            }
            .noorListIconColumn()
        }
    }
    return Container()
}

#Preview("Accessibility size") {
    NoorList {
        NoorBasicSection {
            NoorToggleRow(title: "Stream Audio", image: .stream, isOn: .constant(true))
        }
    }
    .noorListIconColumn()
    .dynamicTypeSize(.accessibility3)
}
