//
//  ReadableInsetsViewModifier.swift
//
//
//  Created by Mohamed Afifi on 2024-01-19.
//

import SwiftUI

private extension EnvironmentValues {
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

    func body(content: Content) -> some View {
        content
            .readWindowSafeAreaInsets($windowSafeAreaInsets)
            .environment(\.readableInsets, ContentDimension.readableInsets(of: windowSafeAreaInsets))
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

extension View {
    public func populateReadableInsets() -> some View {
        modifier(ReadableInsetsModifier())
    }

    public func readableInsetsPadding(_ edges: Edge.Set = .all) -> some View {
        modifier(ReadableInsetsPadding(edges: edges))
    }
}
