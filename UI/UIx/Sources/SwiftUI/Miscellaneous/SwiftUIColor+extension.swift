//
//  SwiftUIColor+extension.swift
//  Quran
//
//  Created by Afifi, Mohamed on 7/10/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import SwiftUI

extension Color {
    public static var systemRed: Color {
        .init(.systemRed)
    }

    public static var systemGreen: Color {
        .init(.systemGreen)
    }

    public static var systemBlue: Color {
        .init(.systemBlue)
    }

    public static var systemOrange: Color {
        .init(.systemOrange)
    }

    public static var systemYellow: Color {
        .init(.systemYellow)
    }

    public static var systemPink: Color {
        .init(.systemPink)
    }

    public static var systemPurple: Color {
        .init(.systemPurple)
    }

    public static var systemTeal: Color {
        .init(.systemTeal)
    }

    public static var systemIndigo: Color {
        .init(.systemIndigo)
    }

    public static var systemGray: Color {
        .init(.systemGray)
    }

    public static var systemGray2: Color {
        .init(.systemGray2)
    }

    public static var systemGray3: Color {
        .init(.systemGray3)
    }

    public static var systemGray4: Color {
        .init(.systemGray4)
    }

    public static var systemGray5: Color {
        .init(.systemGray5)
    }

    public static var systemGray6: Color {
        .init(.systemGray6)
    }
}

/// Foreground colors for static text and related elements.
extension Color {
    /// The color for text labels that contain primary content.
    public static var label: Color {
        .init(.label)
    }

    /// The color for text labels that contain secondary content.
    public static var secondaryLabel: Color {
        .init(.secondaryLabel)
    }

    /// The color for text labels that contain tertiary content.
    public static var tertiaryLabel: Color {
        .init(.tertiaryLabel)
    }

    /// The color for text labels that contain quaternary content.
    public static var quaternaryLabel: Color {
        .init(.quaternaryLabel)
    }
}

extension Color {
    /// A foreground color for standard system links.
    public static var link: Color {
        .init(.link)
    }

    /// A forground color for separators (thin border or divider lines).
    public static var separator: Color {
        .init(.separator)
    }

    /// A forground color intended to look similar to `Color.separated`, but is guaranteed to be opaque, so it will.
    public static var opaqueSeparator: Color {
        .init(.opaqueSeparator)
    }
}

extension Color {
    /// The color for the main background of your interface.
    public static var systemBackground: Color {
        .init(.systemBackground)
    }

    /// The color for content layered on top of the main background.
    public static var secondarySystemBackground: Color {
        .init(.secondarySystemBackground)
    }

    /// The color for content layered on top of secondary backgrounds.
    public static var tertiarySystemBackground: Color {
        .init(.tertiarySystemBackground)
    }

    /// The color for the main background of your grouped interface.
    public static var systemGroupedBackground: Color {
        .init(.systemGroupedBackground)
    }

    /// The color for content layered on top of the main background of your grouped interface.
    public static var secondarySystemGroupedBackground: Color {
        .init(.secondarySystemGroupedBackground)
    }

    /// The color for content layered on top of secondary backgrounds of your grouped interface.
    public static var tertiarySystemGroupedBackground: Color {
        .init(.tertiarySystemGroupedBackground)
    }
}

/// Fill colors for UI elements.
/// These are meant to be used over the background colors, since their alpha component is less than 1.
extension Color {
    /// A color  appropriate for filling thin and small shapes.
    ///
    /// Example: The track of a slider.
    public static var systemFill: Color {
        .init(.systemFill)
    }

    /// A color appropriate for filling medium-size shapes.
    ///
    /// Example: The background of a switch.
    public static var secondarySystemFill: Color {
        .init(.secondarySystemFill)
    }

    /// A color appropriate for filling large shapes.
    ///
    /// Examples: Input fields, search bars, buttons.
    public static var tertiarySystemFill: Color {
        .init(.tertiarySystemFill)
    }

    /// A color appropriate for filling large areas containing complex content.
    ///
    /// Example: Expanded table cells.
    public static var quaternarySystemFill: Color {
        .init(.quaternarySystemFill)
    }
}
