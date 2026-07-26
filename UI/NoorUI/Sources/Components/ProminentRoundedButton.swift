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
    let image: NoorSystemImage?
    let action: AsyncAction

    public init(label: String, image: NoorSystemImage? = nil, action: @escaping AsyncAction) {
        self.label = label
        self.image = image
        self.action = action
    }

    public var body: some View {
        AsyncButton(action: action) {
            buttonLabel
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

    @ViewBuilder
    private var buttonLabel: some View {
        if let image {
            Label {
                Text(label)
            } icon: {
                image.image
            }
        } else {
            Text(label)
        }
    }
}
