//
//  AudioToolbarLayout.swift
//
//
//  Created by Mohamed Afifi on 2026-11-24.
//

import UIKit

/// How many of the audio controls fit in a vertical bar, like iPhone Duo's, while audio plays.
enum AudioToolbarLayout: Equatable {
    /// Stop, speed, the transport capsule and options: the unfolded screen's tall column.
    case full
    /// The transport capsule and one audio menu: the folded screen in portrait.
    case transportAndMenu
    /// Play/pause and one audio menu: the folded screen in landscape, whose column also holds the camera.
    case playPauseAndMenu

    // MARK: Lifecycle

    /// The unfolded iPhone Duo is regular in both size classes; the folded screen is compact in width in portrait
    /// and in height in landscape.
    init(horizontalSizeClass: UIUserInterfaceSizeClass, verticalSizeClass: UIUserInterfaceSizeClass) {
        if verticalSizeClass == .compact {
            self = .playPauseAndMenu
        } else if horizontalSizeClass == .regular {
            self = .full
        } else {
            self = .transportAndMenu
        }
    }
}
