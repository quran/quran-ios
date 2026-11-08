//
//  NoteCircle.swift
//
//
//  Created by Afifi, Mohamed on 7/25/21.
//

import SwiftUI

struct NoteCircle: View {
    @ScaledMetric var minLength: CGFloat = 35

    var color: Color
    var selected: Bool

    var body: some View {
        ColoredCircle(color: color, selected: selected, minLength: minLength)
    }
}

/// A color swatch with a faint outline, so light colors stay visible.
public struct ColoredCircle: View {
    // MARK: Lifecycle

    public init(color: Color, selected: Bool = false, minLength: CGFloat) {
        self.color = color
        self.selected = selected
        self.minLength = minLength
    }

    // MARK: Public

    public var body: some View {
        ZStack {
            Circle()
                .fill(color)
            Circle()
                .stroke(Color.tertiarySystemGroupedBackground, lineWidth: 1)
            if selected {
                Circle()
                    .stroke(Color.label, lineWidth: 2)
            }
        }
        .frame(width: minLength, height: minLength)
    }

    // MARK: Private

    private let color: Color
    private let selected: Bool
    private let minLength: CGFloat
}
