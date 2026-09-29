//
//  AppIconPreview.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import SwiftUI

/// A Home Screen icon drawn at `length` points with the rounded corners iOS gives icons.
struct AppIconPreview: View {
    // MARK: Lifecycle

    init(_ image: Image, length: CGFloat) {
        self.image = image
        self.length = length
    }

    // MARK: Internal

    /// The corner radius iOS uses for an icon, relative to its length.
    static let cornerRadiusRatio: CGFloat = 0.2237

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: length, height: length)
            .clipShape(RoundedRectangle(cornerRadius: length * Self.cornerRadiusRatio, style: .continuous))
            .accessibilityHidden(true)
    }

    // MARK: Private

    private let image: Image
    private let length: CGFloat
}

#Preview {
    HStack {
        AppIconPreview(Image(systemName: "book.closed.fill"), length: 30)
        AppIconPreview(Image(systemName: "book.closed.fill"), length: 56)
    }
}
