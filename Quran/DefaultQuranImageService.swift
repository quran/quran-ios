//
//  DefaultQuranImageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class DefaultQuranImageService: QuranImageService {

    let imagesCache: NSCache<NSNumber, UIImage>

    fileprivate let preloadPreviousImagesCount = 1
    fileprivate let preloadNextImagesCount = 2

    fileprivate let queue = OperationQueue()

    init(imagesCache: NSCache<NSNumber, UIImage>) {
        self.imagesCache = imagesCache

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(DefaultQuranImageService.memoryWarning),
            name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
            object: nil)
    }

    @objc func memoryWarning() {
        imagesCache.removeAllObjects()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate var inProgressOperations: [Int: ImagePreloadingOperation] = [:]
    fileprivate let lock = NSLock()

    internal func getImageOfPage(_ page: Int, forSize size: CGSize, onCompletion: @escaping (UIImage) -> Void) {

        let image = lock.execute { imagesCache.object(forKey: NSNumber(value: page)) }

        if let image = image as UIImage! {
            onCompletion(image)

            // schedule for close images
            cachePagesCloserToPage(page)
            return
        }

        // preload requested page with very high priority and QoS
        preload(page, priority: .veryHigh, qualityOfService: .userInitiated) { (page, image) in
            Queue.main.async {
                onCompletion(image)
            }
        }

        // schedule for close images
        cachePagesCloserToPage(page)
    }

    fileprivate func cachePagesCloserToPage(_ page: Int) {
        // load next pages
        for index in 0..<preloadNextImagesCount {
            let targetPage = page + 1 + index
            if !((imagesCache.object(forKey: NSNumber(value: targetPage)) != nil)) {
                preload(targetPage, onCompletion: { _ in })
            }
        }

        // load previous pages
        for index in 0..<preloadPreviousImagesCount {
            let targetPage = page - 1 - index
            if !((imagesCache.object(forKey: NSNumber(value: targetPage)) != nil)) {
                preload(targetPage, onCompletion: { _ in })
            }
        }
    }

    func preload(_ page: Int,
                 priority: Operation.QueuePriority = .normal,
                 qualityOfService: QualityOfService = .background,
                 onCompletion: @escaping (Int, UIImage) -> Void) {
        guard Quran.QuranPagesRange.contains(page) else {
            return // does nothing
        }

        lock.execute {
            if let operation = inProgressOperations[page] {
                operation.addCompletionBlock(onCompletion)
            } else {

                // create the operation
                let operation = ImagePreloadingOperation(page: page)

                // cache the result
                operation.addCompletionBlock { [weak self] page, image in
                    Queue.main.async {
                        self?.lock.execute {
                            // cache the image
                            self?.imagesCache.setObject(image, forKey: NSNumber(value: page))
                            // remove from in progress
                            _ = self?.inProgressOperations.removeValue(forKey: page)
                        }
                    }
                }

                // on complete
                operation.addCompletionBlock(onCompletion)

                // add it to the in progress
                inProgressOperations[page] = operation
                queue.addOperation(operation)
            }
        }
    }
}
