//
//  QuranImageService.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

// Implementation should use reasonable caching and preloading next pages
protocol QuranImageService {
    func getImageOfPage(_ page: Int, forSize size: CGSize, onCompletion: @escaping (UIImage) -> Void)
}
