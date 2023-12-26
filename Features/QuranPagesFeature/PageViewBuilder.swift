//
//  PageViewBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranKit
import UIKit

@MainActor
public protocol PageViewBuilder {
    func build(at page: Page) -> PageView
}

@MainActor
public protocol PageView: UIViewController {
    var page: Page { get }

    func word(at point: CGPoint) -> Word?
    func verse(at point: CGPoint) -> AyahNumber?
}
