//
//  NoorMenuGroupSeparator.swift
//
//
//  Created by Mohamed Afifi on 2026-11-16.
//

import SwiftUI
import UIx

/// The line between two groups of a popover menu whose rows sit on the popover background.
///
/// It's 1pt, since a hairline `Divider` is barely visible on the popover's Liquid Glass.
/// Place one between consecutive visible groups only, never at the menu's ends.
public struct NoorMenuGroupSeparator: View {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var body: some View {
        Rectangle()
            .fill(Color.separator)
            .frame(height: 1)
            .padding(.horizontal)
            .padding(.vertical, groupSpacing)
    }

    // MARK: Private

    @ScaledMetric private var groupSpacing = 8.0
}

#Preview {
    VStack(alignment: .leading, spacing: 0) {
        Text(verbatim: "First group")
            .padding()
        NoorMenuGroupSeparator()
        Text(verbatim: "Second group")
            .padding()
    }
    .background(.regularMaterial)
}
