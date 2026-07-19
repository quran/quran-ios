//
//  ActiveRoundedButton.swift
//
//
//  Created by Mohamed Afifi on 2024-09-29.
//

import SwiftUI
import UIx

public struct ActiveRoundedButton: View {
    let label: String
    let action: AsyncAction

    public init(label: String, action: @escaping AsyncAction) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        AsyncButton(action: action) {
            Text(label)
                .foregroundColor(.white)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    RoundedActiveBackground(cornerRadius: 100)
                )
        }
        .buttonStyle(.borderless)
    }
}

private struct RoundedActiveBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.appIdentity.opacity(0.8))
            .shadow(color: .systemGray3, radius: 2)
    }
}
