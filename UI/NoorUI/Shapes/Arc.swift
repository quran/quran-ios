//
//  Arc.swift
//
//
//  Created by Mohamed Afifi on 2023-06-29.
//

import SwiftUI

struct Arc: InsettableShape {
    // MARK: Lifecycle

    init(startAngle: Angle, endAngle: Angle, clockwise: Bool) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
    }

    init(circlePercentage: Double) {
        startAngle = .degrees(0)
        endAngle = .degrees(360 * circlePercentage)
        clockwise = true
    }

    // MARK: Internal

    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool

    var insetAmount = 0.0

    func path(in rect: CGRect) -> Path {
        let rotationAdjustment = Angle.degrees(90)
        let modifiedStart = startAngle - rotationAdjustment
        let modifiedEnd = endAngle - rotationAdjustment

        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2 - insetAmount, startAngle: modifiedStart, endAngle: modifiedEnd, clockwise: !clockwise)

        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var arc = self
        arc.insetAmount += amount
        return arc
    }
}
