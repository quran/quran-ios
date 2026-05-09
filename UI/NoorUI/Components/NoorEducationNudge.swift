//
//  NoorEducationNudge.swift
//
//  Created by Ahmed Nabil on 2026-05-09.
//

import SwiftUI

public struct NoorEducationNudge: View {
    // MARK: Lifecycle

    public init(
        titlePrefix: String,
        titleLink: String,
        message: String,
        actionTitle: String,
        initiallyExpanded: Bool,
        action: @escaping () async -> Void
    ) {
        self.titlePrefix = titlePrefix
        self.titleLink = titleLink
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading, spacing: ContentDimension.interSpacing) {
            HStack(spacing: ContentDimension.interSpacing) {
                Button(action: { isExpanded.toggle() }) {
                    title
                }
                .buttonStyle(.plain)

                Spacer(minLength: ContentDimension.interSpacing)

                Button(actionTitle) {
                    Task {
                        await action()
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundColor(Color.appIdentity)
            }

            if isExpanded {
                HStack(alignment: .top, spacing: ContentDimension.interSpacing) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                    Text(message)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, ContentDimension.interSpacing * 2)
        .padding(.horizontal, ContentDimension.interSpacing * 3)
        .background(
            RoundedRectangle(cornerRadius: Dimensions.cornerRadius)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: Private

    private let titlePrefix: String
    private let titleLink: String
    private let message: String
    private let actionTitle: String
    private let action: () async -> Void

    @State private var isExpanded: Bool

    private var title: Text {
        Text(titlePrefix)
            .font(.body.weight(.semibold))
            + Text(titleLink)
            .font(.body.weight(.semibold))
            .underline(!isExpanded)
    }
}
