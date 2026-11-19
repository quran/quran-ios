//
//  VerticalBarPageChrome.swift
//
//
//  Created by Mohammad Abdurraafay on 2026-11-07.
//

import SwiftUI

/// The side of a page, as seen on screen, that faces another page instead of the window's edge.
///
/// On iPhone Duo, `populateReadableInsets()` skips the window's safe area on this side, so the vertical bar's
/// column inset, or the other edge's, doesn't land in the middle of a two-page spread.
public enum PageInnerSide {
    case left
    case right
}

extension EnvironmentValues {
    /// The side of the page that faces another page in a two-page spread, if any.
    var pageInnerSide: PageInnerSide? {
        get { self[PageInnerSideKey.self] }
        set { self[PageInnerSideKey.self] = newValue }
    }
}

private struct PageInnerSideKey: EnvironmentKey {
    static let defaultValue: PageInnerSide? = nil
}

extension View {
    /// Marks the page's side that faces another page, so its readable insets skip the window's safe area there.
    public func pageInnerSide(_ side: PageInnerSide) -> some View {
        environment(\.pageInnerSide, side)
    }
}
