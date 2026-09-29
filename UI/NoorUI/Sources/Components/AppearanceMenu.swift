//
//  AppearanceMenu.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Localization
import SwiftUI
import UIx

/// The appearance mode as a list row that opens a menu.
public struct AppearanceMenu: View {
    // MARK: Lifecycle

    public init(appearanceMode: Binding<AppearanceMode>) {
        _appearanceMode = appearanceMode
    }

    // MARK: Public

    public var body: some View {
        Menu {
            Picker(l("theme.appearance"), selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Label(mode.localizedName, systemImage: mode.systemImageName)
                        .tag(mode)
                }
            }
        } label: {
            // Menu labels take the tint; keep the row neutral like its neighbors.
            HStack {
                NoorSystemImage.appearance.image
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading) {
                        title
                        value
                    }
                    Spacer()
                } else {
                    title
                    Spacer()
                    value
                }
            }
            .foregroundColor(.primary)
        }
    }

    // MARK: Private

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding private var appearanceMode: AppearanceMode

    private var title: some View {
        Text(l("theme.appearance"))
    }

    private var value: some View {
        HStack {
            Text(appearanceMode.localizedName)
                .foregroundColor(.secondaryLabel)
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.tertiaryLabel)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    struct Container: View {
        @State var appearanceMode = AppearanceMode.auto

        var body: some View {
            NoorList {
                NoorBasicSection {
                    AppearanceMenu(appearanceMode: $appearanceMode)
                }
            }
        }
    }
    return Container()
}
