//
//  UIColor+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit

extension UIColor {
    public convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    public convenience init(gray: CGFloat, a: CGFloat = 1) {
        self.init(r: gray, g: gray, b: gray, a: a)
    }

    public convenience init(rgb: Int) {
        self.init(
            r: CGFloat((rgb >> 16) & 0xFF),
            g: CGFloat((rgb >> 08) & 0xFF),
            b: CGFloat((rgb >> 00) & 0xFF)
        )
    }

    public func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255) << 0

        return String(format: "#%06x", rgb)
    }

    public func rgba() -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r * 255, g * 255, b * 255, a]
    }

    public func image(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(rect.size)
        setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    // Hypothetical helper that returns a luminance value (0 for black, 1 for white)
    private var luminance: CGFloat {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        // This is a rough approximation
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // Blends two colors using a given factor.
    // factor = 0 returns self, factor = 1 returns the other color.
    private func blended(with color: UIColor, factor: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 * (1 - factor) + r2 * factor,
            green: g1 * (1 - factor) + g2 * factor,
            blue: b1 * (1 - factor) + b2 * factor,
            alpha: 1.0
        ) // We'll apply alpha separately.
    }

    // Creates a secondary label color based on the receiver (the label color).
    private func secondaryLabelVariantDefaultTraits() -> UIColor {
        // Use a blend factor of about 0.31 (derived from default system values)
        let blendFactor: CGFloat = 0.31
        // Choose a reference color depending on whether the label color is light or dark.
        // For light label colors (high luminance), we use the dark-mode reference.
        let lightReference = UIColor(red: 193 / 255.0, green: 193 / 255.0, blue: 216 / 255.0, alpha: 1.0)
        let darkReference = UIColor(red: 190 / 255.0, green: 190 / 255.0, blue: 222 / 255.0, alpha: 1.0)
        let reference = luminance < 0.5 ? lightReference : darkReference
        // Blend the label color with the chosen reference.
        let blendedColor = blended(with: reference, factor: blendFactor)
        // Return the blended color with an effective alpha of 0.6.
        return blendedColor.withAlphaComponent(0.6)
    }

    // Generates a secondary background color from the primary background color.
    // For light backgrounds (high luminance), we blend with a dark reference.
    // For dark backgrounds (low luminance), we blend with a light reference.
    private func secondaryBackgroundVariantDefaultTraits() -> UIColor {
        let blendFactor: CGFloat = 0.31
        // For a light primary background (e.g., white), secondary should be slightly darker.
        let darkReference = UIColor(red: 171 / 255.0, green: 171 / 255.0, blue: 187 / 255.0, alpha: 1.0)
        // For a dark primary background (e.g., black), secondary should be slightly lighter.
        let lightReference = UIColor(red: 142 / 255.0, green: 142 / 255.0, blue: 149 / 255.0, alpha: 1.0)

        // Reverse the test: if the primary is light, use the dark reference; if dark, use the light reference.
        let reference = luminance > 0.5 ? darkReference : lightReference
        return blended(with: reference, factor: blendFactor).withAlphaComponent(0.5)
    }

    public func secondaryLabelVariant() -> UIColor {
        UIColor { trait in
            return self.resolvedColor(with: trait).secondaryLabelVariantDefaultTraits()
        }
    }

    public func secondaryBackgroundVariant() -> UIColor {
        UIColor { trait in
            return self.resolvedColor(with: trait).secondaryBackgroundVariantDefaultTraits()
        }
    }

    /// Computes a page separator line variant relative to the label color.
    /// - For dark label colors (luminance < 0.5), blends with white using f ≈ 0.788.
    /// - For light label colors, blends with black using f ≈ 0.212.
    private func pageSeparatorLineVariantDefaultTraits() -> UIColor {
        let blendFactor: CGFloat = 1 - (201 / 255.0) // ~0.212
        if luminance < 0.5 {
            // Dark label (like black) → blend with white
            return blended(with: .white, factor: blendFactor)
        } else {
            // Light label (like white) → blend with black
            return blended(with: .black, factor: blendFactor)
        }
    }

    /// Computes a page separator background variant relative to the label color.
    /// - For dark label colors, blends with white using f ≈ 0.882.
    /// - For light label colors, blends with black using f ≈ 0.118.
    private func pageSeparatorBackgroundVariantDefaultTraits() -> UIColor {
        let blendFactor: CGFloat = 1 - (225 / 255.0) // ~0.118
        if luminance < 0.5 {
            // Dark label → blend with white
            return blended(with: .white, factor: blendFactor)
        } else {
            // Light label → blend with black
            return blended(with: .black, factor: blendFactor)
        }
    }

    public func pageSeparatorLineVariant() -> UIColor {
        UIColor { trait in
            return self.resolvedColor(with: trait).pageSeparatorLineVariantDefaultTraits()
        }
    }

    public func pageSeparatorBackgroundVariant() -> UIColor {
        UIColor { trait in
            return self.resolvedColor(with: trait).pageSeparatorBackgroundVariantDefaultTraits()
        }
    }
}
