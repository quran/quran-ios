//
//  PagesContainer.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-08.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import UIKit

@MainActor
protocol PagesContainer: UIViewController {
    var pages: [UIViewController] { get }
}
