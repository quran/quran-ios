//
//  ContentImageLayoutController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-22.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import QuranGeometry
import UIKit

@MainActor
class ContentImageLayoutController {
    weak var quranImageView: UIImageView?

    var imageScale: WordFrameScale {
        if let quranImageView, let imageSize = quranImageView.image?.size {
            return WordFrameScale.scaling(imageSize: imageSize, into: quranImageView.bounds.size)
        } else {
            return .zero
        }
    }

    var imageWidth: CGFloat {
        quranImageView?.image?.size.width ?? 0
    }
}
