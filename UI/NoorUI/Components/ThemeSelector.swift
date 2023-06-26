//
//  ThemeSelector.swift
//
//
//  Created by Afifi, Mohamed on 9/5/21.
//

import Localization
import SwiftUI
import UIx

public struct ThemeSelector: View {
    // MARK: Lifecycle

    public init(theme: Binding<Theme>) {
        _theme = theme
    }

    // MARK: Public

    public var body: some View {
        HStack {
            Spacer()
            ThemeSelection(label: l("theme.light"), selected: theme == .light) {
                theme = .light
            }
            ThemeSelection(label: l("theme.dark"), selected: theme == .dark) {
                theme = .dark
            }
            ThemeSelection(label: l("theme.auto"), selected: theme == .auto) {
                theme = .auto
            }
            Spacer()
        }
    }

    // MARK: Internal

    @Binding var theme: Theme
}

private struct ThemeSelection: View {
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

struct ThemeSelector_Previews: PreviewProvider {
    struct Container: View {
        @State var theme: Theme

        var body: some View {
            ThemeSelector(theme: $theme)
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Container(theme: .auto)
        }
    }
}
