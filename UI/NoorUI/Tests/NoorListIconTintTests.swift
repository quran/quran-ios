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
    func test_iconWithoutColor_followsTheWindowTintLive() async {
        let window = window(showing: NoorListIcon { icon })

        window.tintColor = .red
        await waitUntil(window, renders: .red)

        window.tintColor = .blue
        await waitUntil(window, renders: .blue)
        XCTAssertFalse(window.renders { $0.isClose(to: .red) })
    }

    func test_listItemIconWithoutColor_usesTheWindowTintAndKeepsTheTitlePrimary() async {
        let window = window(showing: NoorListItem(image: .init(icon), title: "Title"))
        window.tintColor = .red

        await waitUntil(window, renders: .red)
        // A tinted title would draw no dark neutral pixels.
        XCTAssertTrue(window.renders(\.isDarkNeutral))
    }

    func test_listItemIconWithColor_keepsItsColor() async {
        let window = window(showing: NoorListItem(image: .init(icon, color: Color(UIColor.green)), title: "Title"))
        window.tintColor = .red

        await waitUntil(window, renders: .green)
        XCTAssertFalse(window.renders { $0.isClose(to: .red) })
    }

    func test_menuRowIcon_usesTheWindowTintAndKeepsTheTitlePrimary() async {
        // Menu labels take the tint; only the icon should.
        let window = window(
            showing: NoorMenuRow(
                title: "Title",
                image: .stop,
                items: ["Value"],
                selection: .constant("Value"),
                label: { $0 }
            )
        )
        window.tintColor = .red

        await waitUntil(window, renders: .red)
        XCTAssertTrue(window.renders(\.isDarkNeutral))
    }

    // MARK: Private

    private let size = CGSize(width: 200, height: 60)

    private var icon: Image {
        Image(systemName: "square.fill")
    }

    private func window(showing content: some View) -> UIWindow {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.overrideUserInterfaceStyle = .light
        window.rootViewController = UIHostingController(rootView: content)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return window
    }

    private func waitUntil(
        _ window: UIWindow,
        renders color: UIColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                MainActor.assumeIsolated { window.renders { $0.isClose(to: color) } }
            },
            object: nil
        )
        let result = await XCTWaiter.fulfillment(of: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Never rendered \(color)", file: file, line: line)
    }
}

extension UIWindow {
    /// Whether any rendered pixel matches `predicate`.
    fileprivate func renders(_ predicate: (RGB) -> Bool) -> Bool {
        layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let image = UIGraphicsImageRenderer(size: bounds.size, format: format).image { context in
            layer.render(in: context.cgContext)
        }
        return pixels(of: image).contains(where: predicate)
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

    /// Primary label text in light mode.
    var isDarkNeutral: Bool {
        let channels = [Int(red), Int(green), Int(blue)]
        return channels.allSatisfy { $0 < 80 } && channels.max()! - channels.min()! <= 10
    }

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
