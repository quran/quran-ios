//
//  ReaderVisibilityAnimation.swift
//

import SwiftUI
import UIKit

public enum ReaderVisibilityAnimation {
    public static var animation: Animation {
        if #available(iOS 18.0, *) {
            .smooth(duration: duration)
        } else {
            .easeInOut(duration: duration)
        }
    }

    @MainActor
    public static func animate(changes: @escaping () -> Void, completion: (() -> Void)? = nil) {
        if #available(iOS 18.0, *) {
            // Use the same animation for UIKit bars and SwiftUI annotations.
            UIView.animate(animation, changes: changes, completion: completion)
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
