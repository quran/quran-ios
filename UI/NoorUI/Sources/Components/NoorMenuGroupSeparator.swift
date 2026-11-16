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

    /// - Parameter insetsHorizontally: Insets the line by the standard padding, to line up with rows that pad
    ///   their own content. Pass `false` when the groups are already inside padded content.
    public init(insetsHorizontally: Bool = true) {
        self.insetsHorizontally = insetsHorizontally
    }

    // MARK: Public

    public var body: some View {
        Rectangle()
            .fill(Color.separator)
            .frame(height: 1)
            .padding(insetsHorizontally ? .horizontal : [])
            .padding(.vertical, groupSpacing)
    }

    // MARK: Private

    private let insetsHorizontally: Bool

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
