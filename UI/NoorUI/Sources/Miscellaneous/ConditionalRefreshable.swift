//
//  ConditionalRefreshable.swift
//

import SwiftUI
import UIx

extension View {
    /// Adds pull-to-refresh running `action` while `isEnabled`.
    ///
    /// - Important: Each change of `isEnabled` replaces the view, resetting its state and scroll position. Tie it only
    ///   to rarely changing state, such as being signed in, and apply it inside modifiers whose work must outlive the
    ///   change, such as `.task`.
    @ViewBuilder
    public func refreshable(isEnabled: Bool, action: @escaping AsyncAction) -> some View {
        if isEnabled {
            refreshable { await action() }
        } else {
            self
        }
    }
}
