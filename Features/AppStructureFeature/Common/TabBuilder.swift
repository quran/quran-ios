//
//  TabBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import UIKit

@MainActor
protocol TabBuildable {
    func build() -> UIViewController
}
