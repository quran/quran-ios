//
//  NoorListIconTintTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import SwiftUI
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NoorListIconTintTests: XCTestCase {
    func test_iconWithoutColor_followsTheWindowTintLive() {
        let window = window(showing: NoorListIcon { icon })

        window.tintColor = .red
        XCTAssertTrue(renders(window, .red))

        window.tintColor = .blue
        XCTAssertTrue(renders(window, .blue))
        XCTAssertFalse(renders(window, .red))
    }

    func test_listItemIconWithoutColor_usesTheWindowTint() {
        let window = window(showing: NoorListItem(image: .init(icon), title: "Title"))
        window.tintColor = .red

        XCTAssertTrue(renders(window, .red))
    }

    func test_listItemIconWithColor_keepsItsColor() {
        let window = window(showing: NoorListItem(image: .init(icon, color: Color(UIColor.green)), title: "Title"))
        window.tintColor = .red

        XCTAssertTrue(renders(window, .green))
        XCTAssertFalse(renders(window, .red))
    }

    // MARK: Private

    private let size = CGSize(width: 200, height: 60)

    private var icon: Image {
        Image(systemName: "square.fill")
    }

    private func window(showing content: some View) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = UIHostingController(rootView: content)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return window
    }

    /// Whether any rendered pixel is `color`.
    private func renders(_ window: UIWindow, _ color: UIColor) -> Bool {
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            window.layer.render(in: context.cgContext)
        }
        return pixels(of: image).contains { $0.isClose(to: color) }
    }

    private func pixels(of image: UIImage) -> [RGB] {
        guard let cgImage = image.cgImage else {
            return []
        }
        let width = cgImage.width
        let height = cgImage.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: data.count, by: 4).map { RGB(red: data[$0], green: data[$0 + 1], blue: data[$0 + 2]) }
    }
}

private struct RGB {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    func isClose(to color: UIColor) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        let tolerance = 10
        return abs(Int(self.red) - Int(red * 255)) <= tolerance
            && abs(Int(self.green) - Int(green * 255)) <= tolerance
            && abs(Int(self.blue) - Int(blue * 255)) <= tolerance
    }
}
