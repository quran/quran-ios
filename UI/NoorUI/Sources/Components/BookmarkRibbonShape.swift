//
//  BookmarkRibbonShape.swift
//

import SwiftUI

/// A book ribbon: a rectangle whose bottom edge is cut into a V notch.
struct BookmarkRibbonShape: Shape {
    // MARK: Lifecycle

    /// - Parameter notchDepth: How far the notch rises into the ribbon, as a ratio of its width.
    init(notchDepth: CGFloat = 0.3) {
        self.notchDepth = notchDepth
    }

    // MARK: Public

    func path(in rect: CGRect) -> Path {
        let notch = min(rect.width * notchDepth, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    // MARK: Private

    private let notchDepth: CGFloat
}

#Preview {
    HStack(alignment: .top) {
        BookmarkRibbonShape()
            .fill(.teal)
            .frame(width: 16, height: 60)
        BookmarkRibbonShape(notchDepth: 0.5)
            .fill(.orange)
            .frame(width: 24, height: 40)
    }
    .padding()
}
