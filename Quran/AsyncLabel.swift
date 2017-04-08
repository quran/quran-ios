//
//  AsyncLabel.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/28/17.
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

class AsyncLabel: UIView {

    static var sharedRenderer: AnyCacheableService<TranslationTextLayout, UIImage>  = {
        let cache = Cache<TranslationTextLayout, UIImage>()
        cache.countLimit = 20
        let creator = AnyCreator { TextRenderPreloadingOperation(layout: $0).asPreloadingOperationRepresentable() }
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let renderer = OperationCacheableService(queue: queue, cache: cache, operationCreator: creator).asCacheableService()
        return renderer
    }()

    var onImageChanged: ((UIImage?) -> Void)?

    var textLayout: TranslationTextLayout? {
        didSet {
            if oldValue != textLayout {
                renderTextInBackground()
            }
        }
    }

    private(set) var image: UIImage? {
        set {
            imageView.image = newValue
            onImageChanged?(image)
        }
        get {
            return imageView.image
        }
    }

    let imageView: UIImageView = UIImageView()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        addAutoLayoutSubview(imageView)
        pinParentHorizontal(imageView)
        addParentTopConstraint(imageView)
    }

    private func renderTextInBackground() {
        guard let textLayout = textLayout else {
            return
        }

        let renderer = type(of: self).sharedRenderer

        renderer.getOnMainThread(textLayout) { [weak self] image in
            self?.image = image
        }
    }

    override var intrinsicContentSize: CGSize {
        return imageView.intrinsicContentSize
    }
}
