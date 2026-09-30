//
//  NoorListIcon.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI

/// A list row's leading icon. In lists that opt in with `noorListIconColumn()`, the icon is
/// centered in a fixed-width column so row titles line up regardless of each symbol's width.
public struct NoorListIcon<Content: View>: View {
    // MARK: Lifecycle

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    // MARK: Public

    public var body: some View {
        if usesIconColumn {
            content
                .frame(width: width)
        } else {
            content
        }
    }

    // MARK: Private

    @Environment(\.usesNoorListIconColumn) private var usesIconColumn
    @ScaledMetric(relativeTo: .body) private var width = 30.0

    private let content: Content
}

extension View {
    /// Lines up row titles by centering each `NoorListIcon` in a fixed-width column.
    public func noorListIconColumn() -> some View {
        environment(\.usesNoorListIconColumn, true)
    }
}

private struct UsesNoorListIconColumnKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    fileprivate var usesNoorListIconColumn: Bool {
        get { self[UsesNoorListIconColumnKey.self] }
        set { self[UsesNoorListIconColumnKey.self] = newValue }
    }
}
