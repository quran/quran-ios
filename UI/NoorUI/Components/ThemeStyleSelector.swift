//
//  ThemeStyleSelector.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-25.
//
import SwiftUI

private struct ThemeStyleOptionView: View {
    let themeStyle: ThemeStyle
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var borderWidth = 3.0

    var body: some View {
        Button {
            if !isSelected {
                action()
            }
        }
        label: {
            VStack {
                Text("نور")
                    .font(.largeTitle)
                    .themedForeground()

                Text(themeStyle.localizedName)
                    .themedForeground()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .themedBackground()
            .cornerRadius(cornerRadius)
            .appearanceModeColorSchema()
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.label, lineWidth: isSelected ? borderWidth : 0)
            }
            .shadow(color: .secondaryLabel, radius: 1)
        }
        .environment(\.themeStyle, themeStyle)
    }
}

public struct ThemeStyleSelector: View {
    @Binding var selectedStyle: ThemeStyle

    public init(selectedStyle: Binding<ThemeStyle>) {
        _selectedStyle = selectedStyle
    }

    let columns = [
        GridItem(.adaptive(minimum: 100)),
    ]

    let styles = ThemeStyle.styles

    public var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(styles, id: \.self) { style in
                ThemeStyleOptionView(
                    themeStyle: style,
                    isSelected: selectedStyle == style
                ) { selectedStyle = style }
            }
        }
        .padding()
    }
}

private extension ThemeStyle {
    // TODO: Add localization
    var localizedName: String {
        switch self {
        case .paper:
            return "Paper"
        case .calm:
            return "Calm"
        case .focus:
            return "Focus"
        case .original:
            return "Original"
        case .quiet:
            return "Quiet"
        }
    }
}

#Preview {
    struct Container: View {
        @State var selectedStyle: ThemeStyle = .focus

        var body: some View {
            VStack {
                ThemeStyleSelector(selectedStyle: $selectedStyle)
                    .padding()
            }
        }
    }
    return Container()
}
