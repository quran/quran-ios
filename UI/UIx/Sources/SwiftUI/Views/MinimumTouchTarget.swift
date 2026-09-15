import SwiftUI

public extension View {
    /// Gives a control label a rectangular touch target of at least 44 points.
    /// Apply inside the button label so the entire padded area responds to taps.
    func minimumTouchTarget() -> some View {
        modifier(MinimumTouchTargetModifier())
    }
}

private struct MinimumTouchTargetModifier: ViewModifier {
    private let minimumLength: CGFloat = 44

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minimumLength, minHeight: minimumLength)
            .contentShape(Rectangle())
    }
}

#Preview {
    Button {} label: {
        Image(systemName: "plus")
            .minimumTouchTarget()
            .border(.secondary)
    }
}
