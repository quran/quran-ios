//
//  ProminentRoundedButton.swift
//
//

import SwiftUI
import UIx

public struct ProminentRoundedButton: View {
    @ScaledMetric private var cornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var verticalPadding = 10.0

    let label: String
    let action: AsyncAction

    public init(label: String, action: @escaping AsyncAction) {
        self.label = label
        self.action = action
    }

    public var body: some View {
        AsyncButton(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.accentColor)
                )
        }
        .buttonStyle(.plain)
    }
}
