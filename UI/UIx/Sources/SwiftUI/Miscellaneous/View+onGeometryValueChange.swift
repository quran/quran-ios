import SwiftUI

extension View {
    /// Reports a geometry value on appearance and whenever it changes, using a view-scoped task.
    public func onGeometryValueChange<Value: Equatable>(
        of transform: @escaping (GeometryProxy) -> Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        background {
            GeometryReader { geometry in
                let value = transform(geometry)
                Color.clear
                    .task(id: value) {
                        action(value)
                    }
            }
        }
    }
}
