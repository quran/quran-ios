//
//  CloseButton.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-26.
//

import SwiftUI

public struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss

    public init() { }

    public var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .font(.title)
                .foregroundStyle(Color.systemGray, Color.systemGray5)
        }
        .accessibilityLabel("Close")
    }
}
