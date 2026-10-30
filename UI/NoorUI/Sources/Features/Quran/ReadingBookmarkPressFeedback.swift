#if QURAN_SYNC
//
//  ReadingBookmarkPressFeedback.swift
//

import SwiftUI

extension View {
    /// Dims a reading bookmark mark while its tap target is pressed, and shrinks it slightly unless Reduce Motion is on.
    func readingBookmarkPressed(_ isPressed: Bool, anchor: UnitPoint = .center) -> some View {
        modifier(ReadingBookmarkPressedModifier(isPressed: isPressed, anchor: anchor))
    }
}

/// Reports a tap target's pressed state, so the mark it covers can show it.
///
/// The marks are drawn apart from their invisible targets (behind the page, or smaller than a touch target),
/// so the target's label can't show the press itself.
struct ReadingBookmarkPressReportingStyle: ButtonStyle {
    let onPressedChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed, perform: onPressedChange)
    }
}

private struct ReadingBookmarkPressedModifier: ViewModifier {
    // MARK: Internal

    let isPressed: Bool
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? Self.pressedOpacity : 1)
            .scaleEffect(isPressed && !reduceMotion ? Self.pressedScale : 1, anchor: anchor)
            .animation(NoorAnimation.standard, value: isPressed)
    }

    // MARK: Private

    private static let pressedOpacity: CGFloat = 0.4
    private static let pressedScale: CGFloat = 0.92

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
}
#endif
