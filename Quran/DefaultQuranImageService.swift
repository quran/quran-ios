//
//  DefaultQuranImageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

struct DefaultQuranImageService: QuranImageService {

    func getImageOfPage(page: QuranPage, forSize size: CGSize, onCompletion: UIImage -> Void) {
        guard let image = UIImage(named: fileNameForPage(page.pageNumber)) else {
            fatalError()
        }
        onCompletion(image)

        // cache next page
        Queue.background.async {
            let nextFile = fileNameForPage(page.pageNumber + 1)
            _ = UIImage(named: nextFile)
//            print(nextFile, image)

        }
    }
}

private func fileNameForPage(page: Int) -> String {
    let file = String(format: "images_1280/width_1280/page%03d.png", page)
    return file
}
