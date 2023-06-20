//
//  ReadingImageView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-23.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import AVFoundation
import QuranGeometry
import QuranImageFeature
import SwiftUI

struct ReadingImageView: View {
    let image: UIImage
    let pageMarkers: PageMarkers

    var body: some View {
        ContentImageContentViewWrapper(image: image, pageMarkers: pageMarkers)
            .aspectRatio(image.size, contentMode: .fit)
    }
}

private struct ContentImageContentViewWrapper: UIViewRepresentable {
    let image: UIImage
    let pageMarkers: PageMarkers

    func makeUIView(context: Context) -> ContentImageContentView {
        let view = ContentImageContentView(topView: UIView(frame: .zero), bottomView: UIView(frame: .zero), fullWindowView: false)
        view.image = image
        view.configure(with: pageMarkers)
        return view
    }

    func updateUIView(_ view: ContentImageContentView, context: Context) {
        view.image = image
        view.configure(with: pageMarkers)
    }
}
