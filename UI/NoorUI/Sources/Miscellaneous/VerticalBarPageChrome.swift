//
//  VerticalBarPageChrome.swift
//
//
//  Created by Mohammad Abdurraafay on 2026-11-07.
//

import SwiftUI

/// The side of a page, as seen on screen, that faces another page instead of the window's edge.
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

    /// The window's safe area insets, set by `populateReadableInsets()`.
    var windowSafeAreaInsets: EdgeInsets {
        get { self[WindowSafeAreaInsetsKey.self] }
        set { self[WindowSafeAreaInsetsKey.self] = newValue }
    }

    /// Whether the page header and footer use tighter spacing, because the page's height limits its size.
    var compactsPageChrome: Bool {
        get { self[CompactsPageChromeKey.self] }
        set { self[CompactsPageChromeKey.self] = newValue }
    }

    /// Whether the window reserves a column for the vertical bar, like on iPhone Duo. Set by `populateReadableInsets()`.
    ///
    /// The Quran page layout uses it to apply iPhone Duo's adjustments only there, so iPhone and iPad keep their layout.
    public internal(set) var windowHasVerticalBar: Bool {
        get { self[WindowHasVerticalBarKey.self] }
        set { self[WindowHasVerticalBarKey.self] = newValue }
    }
}

private struct WindowHasVerticalBarKey: EnvironmentKey {
    static let defaultValue = false
}

private struct WindowSafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

private struct CompactsPageChromeKey: EnvironmentKey {
    static let defaultValue = false
}

private struct PageInnerSideKey: EnvironmentKey {
    static let defaultValue: PageInnerSide? = nil
}

private struct CompactsPageChromeModifier: ViewModifier {
    @Environment(\.windowHasVerticalBar) var windowHasVerticalBar
    let isLimitedByHeight: Bool

    func body(content: Content) -> some View {
        content.environment(\.compactsPageChrome, isLimitedByHeight && windowHasVerticalBar)
    }
}

/// Reads whether the window reserves a column for the vertical bar, like on iPhone Duo.
public struct VerticalBarReader<Content: View>: View {
    // MARK: Lifecycle

    public init(@ViewBuilder content: @escaping (Bool) -> Content) {
        self.content = content
    }

    // MARK: Public

    public var body: some View {
        content(windowHasVerticalBar)
    }

    // MARK: Private

    @Environment(\.windowHasVerticalBar) private var windowHasVerticalBar
    private let content: (Bool) -> Content
}

extension View {
    /// Marks the page's side that faces another page, so its readable insets skip the window's safe area there.
    public func pageInnerSide(_ side: PageInnerSide) -> some View {
        environment(\.pageInnerSide, side)
    }

    /// Tightens the spacing of the page header and footer on iPhone Duo, for a page whose height limits its size.
    public func compactsPageChromeOnVerticalBarDisplays(isLimitedByHeight: Bool) -> some View {
        modifier(CompactsPageChromeModifier(isLimitedByHeight: isLimitedByHeight))
    }
}
