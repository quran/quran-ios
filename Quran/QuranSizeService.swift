//
//  QuranSizeService.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

protocol QuranSizeService {
    func pageSizeForBounds(bounds: CGRect) -> CGSize
}
