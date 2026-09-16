import SwiftUI

extension View {
    /// Reports a geometry value on appearance and whenever it changes, using a view-scoped task.
    public func onGeometryValueChange<Value: Equatable>(
        of transform: @escaping (GeometryProxy) -> Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        background {
            GeometryReader { geometry in
                GeometryValueObserver(value: transform(geometry), action: action)
            }
        }
    }
}

// Keep SwiftUI's task return type inside a concrete view. Exposing it through the
// geometry helper causes an undefined opaque type descriptor when archiving with Xcode 26.5.
private struct GeometryValueObserver<Value: Equatable>: View {
    let value: Value
    let action: (Value) -> Void

    var body: some View {
        Color.clear
            .task(id: value) {
                action(value)
            }
    }
}
