//
//  AppearanceModeSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

public struct AppearanceModeSelector: View {
    // MARK: Lifecycle

    public init(appearanceMode: Binding<AppearanceMode>) {
        _appearanceMode = appearanceMode
    }

    // MARK: Public

    public var body: some View {
        HStack {
            Spacer()
            AppearanceModeSelection(label: l("theme.light"), selected: appearanceMode == .light) {
                appearanceMode = .light
            }
            AppearanceModeSelection(label: l("theme.dark"), selected: appearanceMode == .dark) {
                appearanceMode = .dark
            }
            AppearanceModeSelection(label: l("theme.auto"), selected: appearanceMode == .auto) {
                appearanceMode = .auto
            }
            Spacer()
        }
    }

    // MARK: Internal

    @Binding var appearanceMode: AppearanceMode
}

private struct AppearanceModeSelection: View {
    let label: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button {
            if !selected {
                action()
            }
        }
        label: {
            VStack {
                Text(label)
                    .foregroundColor(.label)
                Text("")
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .hidden()
                        .overlay(Circle().stroke(Color.systemGray))
                }
            }
            .padding()
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    struct Container: View {
        @State var appearanceMode: AppearanceMode = .auto

        var body: some View {
            VStack {
                AppearanceModeSelector(appearanceMode: $appearanceMode)
            }
        }
    }
    return Container()
}
