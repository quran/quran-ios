//
//  HomeSegmentBuildable.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import FeaturesSupport
import UIKit

@MainActor
protocol HomeSegmentBuildable {
    func build(withListener listener: QuranNavigator) -> UIViewController
}
