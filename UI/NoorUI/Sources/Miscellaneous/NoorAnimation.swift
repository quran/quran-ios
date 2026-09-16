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

    @MainActor
    public static func animate(changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        if #available(iOS 18.0, *) {
            // Keep UIKit transitions consistent with SwiftUI.
            UIView.animate(standard, changes: changes, completion: completion)
        } else {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: changes,
                completion: { _ in completion?() }
            )
        }
    }

    private static let duration: TimeInterval = 0.3
}
