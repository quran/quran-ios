//
//  ScrollViewPageBehavior.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ScrollViewPageBehavior: NSObject, UIScrollViewDelegate {

    fileprivate (set) dynamic var currentPage: Int = 0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.size.width
        currentPage = Int(round((scrollView.contentOffset.x + (0.5 * width)) / width))
    }
}
