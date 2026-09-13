//
//  View+Placement.swift
//

import SwiftUI

extension View {
    /// Sizes and offsets a view within a top-leading coordinate space.
    public func placed(in rect: CGRect) -> some View {
        frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
    }
}
