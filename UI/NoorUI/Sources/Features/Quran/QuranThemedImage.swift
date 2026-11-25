//
//  QuranThemedImage.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-04-01.
//

import SwiftUI

public struct QuranThemedImage: View {
    // MARK: Lifecycle

    public init(image: UIImage) {
        self.image = image
    }

    // MARK: Public

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .invertThemedColorIfNeeded(flattensImage: true)
    }

    // MARK: Internal

    let image: UIImage
}
