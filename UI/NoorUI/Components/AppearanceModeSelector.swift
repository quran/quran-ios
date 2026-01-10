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
            ForEach([AppearanceMode.light, .dark, .auto], id: \.self) { mode in
                AppearanceModeSelection(label: mode.localizedName, selected: appearanceMode == mode) {
                    appearanceMode = mode
                }
            }
            Spacer()
        }
    }

    // MARK: Internal

    @Binding var appearanceMode: AppearanceMode
}

extension AppearanceMode {
    public var localizedName: String {
        switch self {
        case .auto: l("theme.auto")
        case .light: l("theme.light")
        case .dark: l("theme.dark")
        }
    }
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

struct AppearanceModeSelectorPreview: View {
    @State var appearanceMode: AppearanceMode = .auto

    var body: some View {
        VStack {
            AppearanceModeSelector(appearanceMode: $appearanceMode)
        }
    }
}

#Preview {
    AppearanceModeSelectorPreview()
}
