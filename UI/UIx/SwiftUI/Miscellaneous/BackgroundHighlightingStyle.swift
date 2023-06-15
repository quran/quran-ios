//
//  BackgroundHighlightingStyle.swift
//
//
//  Created by Afifi, Mohamed on 8/1/21.
//

import SwiftUI

@available(iOS 13.0, *)
public struct BackgroundHighlightingStyle: ButtonStyle {
    let highlightingColor: Color
    public init(highlightingColor: Color = .systemFill) {
        self.highlightingColor = highlightingColor
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .background(configuration.isPressed ? highlightingColor : Color.clear)
    }
}
