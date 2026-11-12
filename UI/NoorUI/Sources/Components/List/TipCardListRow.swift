//
//  TipCardListRow.swift
//

import SwiftUI

extension View {
    /// Lays out a ``TipCard`` as a list row, which draws its own background and spans the row.
    public func tipCardListRow() -> some View {
        modifier(TipCardListRow())
    }
}

private struct TipCardListRow: ViewModifier {
    @ScaledMetric private var verticalInset = 6.0

    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets(top: verticalInset, leading: 0, bottom: verticalInset, trailing: 0))
            .listRowBackground(Color.clear)
    }
}
