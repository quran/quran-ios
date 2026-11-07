//
//  ConditionalRefreshable.swift
//

import SwiftUI
import UIx

extension View {
    /// Adds pull-to-refresh that runs `action` while `isEnabled`, and none otherwise.
    ///
    /// - Important: SwiftUI can't turn `refreshable(action:)` off, so every change of `isEnabled` replaces the view
    ///   with a new one, as an `if` would: its state starts over, a list scrolls back to the top, and an animation in
    ///   progress, such as entering edit mode, is lost. Tie `isEnabled` only to state that rarely changes while the
    ///   view is on screen, such as being signed in, never to edit mode or selection. Apply it to the scrolling view
    ///   itself, inside modifiers whose work must outlive the change, such as `task`.
    @ViewBuilder
    public func refreshable(isEnabled: Bool, action: @escaping AsyncAction) -> some View {
        if isEnabled {
            refreshable { await action() }
        } else {
            self
        }
    }
}
