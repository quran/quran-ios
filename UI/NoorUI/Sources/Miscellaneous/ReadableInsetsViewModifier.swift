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

private struct ReadableInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

private struct ReadableInsetsModifier: ViewModifier {
    @State var windowSafeAreaInsets: EdgeInsets = .zero
    @State var windowHasVerticalBar = false
    @Environment(\.pageInnerSide) var pageInnerSide
    @Environment(\.layoutDirection) var layoutDirection

    func body(content: Content) -> some View {
        content
            .readWindowSafeAreaInsets($windowSafeAreaInsets, hasVerticalBar: $windowHasVerticalBar)
            .environment(\.readableInsets, ContentDimension.readableInsets(of: pageSafeAreaInsets))
    }

    /// The window's safe area, except on iPhone Duo on the side facing the other page, which is away from the window's
    /// edge. That side would otherwise take the vertical bar's column inset, or the other edge's, in the spread's middle.
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

    public func readableInsetsPadding(_ edges: Edge.Set = .all) -> some View {
        modifier(ReadableInsetsPadding(edges: edges))
    }

    public func onReadableInsetsChange(_ body: @escaping (EdgeInsets) -> Void) -> some View {
        modifier(ReadableInsetsReader(onChange: body))
    }
}
