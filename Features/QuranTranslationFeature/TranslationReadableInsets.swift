//
//  TranslationReadableInsets.swift
//
//
//  Created by Mohamed Afifi on 2024-01-19.
//

import NoorUI
import SwiftUI

private extension EnvironmentValues {
    var translationReadableInsets: EdgeInsets {
        get { self[TranslationReadableInsetsKey.self] }
        set { self[TranslationReadableInsetsKey.self] = newValue }
    }
}

private struct TranslationReadableInsetsKey: EnvironmentKey {
    static let defaultValue = EdgeInsets()
}

private struct TranslationReadableInsetsModifier: ViewModifier {
    @State var windowSafeAreaInsets: EdgeInsets = .zero

    func body(content: Content) -> some View {
        content
            .readWindowSafeAreaInsets($windowSafeAreaInsets)
            .environment(\.translationReadableInsets, ContentDimension.readableInsets(of: windowSafeAreaInsets))
    }
}

private struct ReadableInsetsPadding: ViewModifier {
    @Environment(\.translationReadableInsets) var readableInsets
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
    func populateReadableInsets() -> some View {
        modifier(TranslationReadableInsetsModifier())
    }

    func readableInsetsPadding(_ edges: Edge.Set = .all) -> some View {
        modifier(ReadableInsetsPadding(edges: edges))
    }
}
