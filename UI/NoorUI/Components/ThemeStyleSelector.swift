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
                Text("الله")
                    .font(.largeTitle)
                    .foregroundColor(Color(themeStyle.textColor))

                Text(themeStyle.localizedName)
                    .foregroundColor(Color(themeStyle.textColor))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding()
            .background(Color(themeStyle.backgroundColor))
            .cornerRadius(cornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.label, lineWidth: isSelected ? borderWidth : 0)
            }
            .shadow(color: .secondaryLabel, radius: 1)
        }
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

    let styles: [ThemeStyle] = [.paper, .original, .quiet, .calm, .focus]

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

    var textColor: UIColor {
        switch self {
        case .calm:
            return .themeCalmText
        case .focus:
            return .themeFocusText
        case .original:
            return .themeOriginalText
        case .paper:
            return .themePaperText
        case .quiet:
            return .themeQuietText
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .calm:
            return .themeCalmBackground
        case .focus:
            return .themeFocusBackground
        case .original:
            return .themeOriginalBackground
        case .paper:
            return .themePaperBackground
        case .quiet:
            return .themeQuietBackground
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
