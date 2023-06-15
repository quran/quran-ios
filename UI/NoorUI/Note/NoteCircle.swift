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

struct ColoredCircle: View {
    let color: Color
    let selected: Bool
    let minLength: CGFloat

    var body: some View {
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
}
