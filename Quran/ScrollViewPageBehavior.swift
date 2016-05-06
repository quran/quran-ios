//
//  ScrollViewPageBehavior.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class ScrollViewPageBehavior: NSObject, UIScrollViewDelegate {

    private (set) dynamic var currentPage: Int = 0

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            _scrollViewDidEndDecelerating(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        _scrollViewDidEndDecelerating(scrollView)
    }

    private func _scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let width = scrollView.frame.size.width
        currentPage = Int(round((scrollView.contentOffset.x + (0.5 * width)) / width))
    }
}
