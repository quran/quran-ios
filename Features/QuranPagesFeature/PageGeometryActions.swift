//
//  PageGeometryActions.swift
//
//
//  Created by Mohamed Afifi on 2024-10-06.
//

import Foundation
import QuranKit
import SwiftUI

@MainActor
public struct PageGeometryActions: Equatable {
    let id: AnyHashable
    public var word: (CGPoint) -> Word?
    public var verse: (CGPoint) -> AyahNumber?

    public init(id: some Hashable, word: @escaping (CGPoint) -> Word?, verse: @escaping (CGPoint) -> AyahNumber?) {
        self.id = id
        self.word = word
        self.verse = verse
    }

    public nonisolated static func == (lhs: PageGeometryActions, rhs: PageGeometryActions) -> Bool {
        return lhs.id == rhs.id
    }
}

private struct PageGeometryActionsPreferenceKey: PreferenceKey {
    public static var defaultValue: [PageGeometryActions] = []
    public static func reduce(value: inout [PageGeometryActions], nextValue: () -> [PageGeometryActions]) {
        value.append(contentsOf: nextValue())
    }
}

@MainActor
private struct PageGeometryActionsViewModifier: ViewModifier {
    let actions: PageGeometryActions
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .preference(key: PageGeometryActionsPreferenceKey.self, value: [actions])
            .onGlobalFrameChanged {
                frame = $0
            }
    }

    private var wrappedActions: PageGeometryActions {
        PageGeometryActions(
            id: actions.id,
            word: { point in
                actions.word(toLocalPoint(point))
            },
            verse: { point in
                actions.verse(toLocalPoint(point))
            }
        )
    }

    func toLocalPoint(_ globalPoint: CGPoint) -> CGPoint {
        CGPoint(
            x: globalPoint.x - frame.minX,
            y: globalPoint.y - frame.minY
        )
    }
}

extension View {
    public func geometryActions(_ actions: PageGeometryActions) -> some View {
        modifier(PageGeometryActionsViewModifier(actions: actions))
    }

    public func collectGeometryActions(_ actions: Binding<[PageGeometryActions]>) -> some View {
        onPreferenceChange(PageGeometryActionsPreferenceKey.self) {
            actions.wrappedValue = $0
        }
    }
}
