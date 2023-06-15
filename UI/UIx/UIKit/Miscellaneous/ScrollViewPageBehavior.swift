//
//  ScrollViewPageBehavior.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
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

open class ScrollViewDelegateNotifier: NSObject, UIScrollViewDelegate {
    open var onScrollViewWillBeginDragging: (() -> Void)?

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onScrollViewWillBeginDragging?()
    }
}

open class ScrollViewPageBehavior: ScrollViewDelegateNotifier {
    @objc open private(set) dynamic var currentPage: Int = 0

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.size.width
        currentPage = Int(round((scrollView.contentOffset.x + (0.5 * width)) / width))
    }
}
