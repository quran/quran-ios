//
//  DefaultQuranImageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ParkBenchTimer {

    let startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()

        return duration ?? 0
    }

    var duration: CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}

class DefaultQuranImageService: QuranImageService {

    let imagesCache: Cache

    private let preloadPreviousImagesCount = 1
    private let preloadNextImagesCount = 2

    private let queue = NSOperationQueue()

    init(imagesCache: Cache) {
        self.imagesCache = imagesCache

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: #selector(DefaultQuranImageService.memoryWarning),
            name: UIApplicationDidReceiveMemoryWarningNotification,
            object: nil)
    }

    @objc func memoryWarning() {
        imagesCache.removeAllObjects()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    private var inProgressOperations: [Int: ImagePreloadingOperation] = [:]
    private let lock = NSLock()

    func getImageOfPage(page: Int, forSize size: CGSize, onCompletion: UIImage -> Void) {

        let image = lock.execute { imagesCache.objectForKey(page) }

        if let image = image as? UIImage {
            onCompletion(image)

            // schedule for close images
            cachePagesCloserToPage(page)
            return
        }

        // preload requested page
        preload(page) { (page, image) in
            Queue.main.async {
                onCompletion(image)
            }
        }

        // schedule for close images
        cachePagesCloserToPage(page)
    }

    private func cachePagesCloserToPage(page: Int) {
        // load next pages
        for index in 0..<preloadNextImagesCount {
            let targetPage = page + 1 + index
            if !(imagesCache.objectForKey(targetPage) is UIImage) {
                preload(targetPage, onCompletion: { _ in })
            }
        }

        // load previous pages
        for index in 0..<preloadPreviousImagesCount {
            let targetPage = page - 1 - index
            if !(imagesCache.objectForKey(targetPage) is UIImage) {
                preload(targetPage, onCompletion: { _ in })
            }
        }
    }

    func preload(page: Int, onCompletion: (Int, UIImage) -> Void) {
        guard Truth.QuranPagesRange.contains(page) else {
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
                            self?.imagesCache.setObject(image, forKey: page)
                            // remove from in progress
                            self?.inProgressOperations.removeValueForKey(page)
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
