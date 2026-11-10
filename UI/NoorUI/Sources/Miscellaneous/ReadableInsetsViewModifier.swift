//
//  ReadableInsetsViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-01-19.
//

import SwiftUI

extension EnvironmentValues {
    /// The page's readable insets, set by `populateReadableInsets()`.
    var readableInsets: EdgeInsets {
        get { self[ReadableInsetsKey.self] }
        set { self[ReadableInsetsKey.self] = newValue }
    }
}

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

private struct ReadableInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

private struct PageInnerSideKey: EnvironmentKey {
    static let defaultValue: PageInnerSide? = nil
}

private struct ReadableInsetsModifier: ViewModifier {
    @State var windowSafeAreaInsets: EdgeInsets = .zero
    @State var windowHasVerticalBar = false
    @Environment(\.pageInnerSide) var pageInnerSide
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        content
            // Quran pages hide the status bar while reading, so they can use the empty vertical bar column.
            .readWindowSafeAreaInsets($windowSafeAreaInsets, excludingVerticalBar: true, hasVerticalBar: $windowHasVerticalBar)
            .environment(\.readableInsets, ContentDimension.readableInsets(of: pageSafeAreaInsets))
            .environment(\.windowSafeAreaInsets, pageSafeAreaInsets)
            .environment(\.windowHasVerticalBar, windowHasVerticalBar)
    }

    /// The window's safe area, except on iPhone Duo on the side facing the other page, which is away from the window's edge.
    private var pageSafeAreaInsets: EdgeInsets {
        var insets = windowSafeAreaInsets
        guard let pageInnerSide, windowHasVerticalBar else {
            return insets
        }
        let innerSideIsLeading = (pageInnerSide == .left) == (layoutDirection == .leftToRight)
        if innerSideIsLeading {
            insets.leading = 0
        } else {
            insets.trailing = 0
        }
        return insets
    }
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

private struct ReadableInsetsPadding: ViewModifier {
    @Environment(\.readableInsets) var readableInsets
    let edges: Edge.Set

    func body(content: Content) -> some View {
        content
            .padding(.top, edges.contains(.top) ? readableInsets.top : 0)
            .padding(.bottom, edges.contains(.bottom) ? readableInsets.bottom : 0)
            .padding(.leading, edges.contains(.leading) ? readableInsets.leading : 0)
            .padding(.trailing, edges.contains(.trailing) ? readableInsets.trailing : 0)
    }
}

private struct ReadableInsetsReader: ViewModifier {
    @Environment(\.readableInsets) var readableInsets
    let onChange: (EdgeInsets) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: readableInsets, perform: onChange)
    }
}

extension View {
    public func populateReadableInsets() -> some View {
        modifier(ReadableInsetsModifier())
    }

    /// Marks the page's side that faces another page, so its readable insets skip the window's safe area there.
    public func pageInnerSide(_ side: PageInnerSide) -> some View {
        environment(\.pageInnerSide, side)
    }

    /// Tightens the spacing of the page header and footer on iPhone Duo, for a page whose height limits its size.
    public func compactsPageChromeOnVerticalBarDisplays(isLimitedByHeight: Bool) -> some View {
        modifier(CompactsPageChromeModifier(isLimitedByHeight: isLimitedByHeight))
    }

    public func readableInsetsPadding(_ edges: Edge.Set = .all) -> some View {
        modifier(ReadableInsetsPadding(edges: edges))
    }

    public func onReadableInsetsChange(_ body: @escaping (EdgeInsets) -> Void) -> some View {
        modifier(ReadableInsetsReader(onChange: body))
    }
}
