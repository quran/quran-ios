//
//  NoorAnimation.swift
//

import SwiftUI
import UIKit

/// Shared animation for ordinary UI transitions, including visibility and layout changes.
public enum NoorAnimation {
    /// A smooth 0.3-second transition with an ease-in-out fallback on older systems.
    public static var standard: Animation {
        if #available(iOS 18.0, *) {
            .smooth(duration: duration)
        } else {
            .easeInOut(duration: duration)
        }
    }

    /// Animates UIKit changes with a critically damped spring that approximates `standard`.
    ///
    /// Never animate UIKit views with `UIView.animate(_:changes:completion:)` and a SwiftUI animation. UIKit advances
    /// those on its in-process animation thread, which can lay out SwiftUI hosting views off the main thread.
    @MainActor
    public static func animate(changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState],
            animations: changes,
            completion: { _ in completion?() }
        )
    }

    private static let duration: TimeInterval = 0.3
}
