//
//  TabSwitchRotation.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import UIKit

/// Decides whether switching tabs should rotate the interface.
enum TabSwitchRotation {
    /// The orientations to request after switching tabs, or `nil` to keep the current one.
    ///
    /// - Parameters:
    ///   - previousTab: The orientations the tab being left supported.
    ///   - targetTab: The orientations the selected tab supports.
    ///   - interface: The interface's current orientation.
    ///   - device: The orientation that matches how the device is held, if known.
    static func orientations(
        previousTab: UIInterfaceOrientationMask,
        targetTab: UIInterfaceOrientationMask,
        interface: UIInterfaceOrientationMask,
        device: UIInterfaceOrientationMask?
    ) -> UIInterfaceOrientationMask? {
        if !targetTab.contains(interface) {
            return targetTab
        }
        // Leaving a tab that couldn't follow the device, like portrait-only Search while the device is
        // in landscape: rotate back to match the device. A tab that could follow it, but was rotated on
        // purpose from the More menu, keeps its orientation.
        if let device, device != interface, !previousTab.contains(device), targetTab.contains(device) {
            return device
        }
        return nil
    }
}
