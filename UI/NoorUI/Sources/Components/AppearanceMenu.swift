//
//  AppearanceMenu.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Localization
import SwiftUI

/// The appearance mode as a list row that opens a menu.
public struct AppearanceMenu: View {
    // MARK: Lifecycle

    public init(appearanceMode: Binding<AppearanceMode>) {
        _appearanceMode = appearanceMode
    }

    // MARK: Public

    public var body: some View {
        NoorMenuRow(
            title: l("theme.appearance"),
            image: .appearance,
            items: AppearanceMode.allCases,
            selection: $appearanceMode,
            value: appearanceMode.localizedName
        ) { mode in
            Label(mode.localizedName, systemImage: mode.systemImageName)
        }
    }

    // MARK: Private

    @Binding private var appearanceMode: AppearanceMode
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
