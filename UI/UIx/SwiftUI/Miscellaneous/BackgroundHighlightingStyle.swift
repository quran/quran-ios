//
//  BackgroundHighlightingStyle.swift
//
//
//  Created by Afifi, Mohamed on 8/1/21.
//

import SwiftUI

public struct BackgroundHighlightingStyle: ButtonStyle {
    // MARK: Lifecycle

    public init(highlightingColor: Color = .systemFill) {
        self.highlightingColor = highlightingColor
    }

    // MARK: Public

    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .background(configuration.isPressed ? highlightingColor : Color.clear)
    }

    // MARK: Internal

    let highlightingColor: Color
}
