//
//  SurasNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

final class SurasTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        return UITabBarItem(title: lAndroid("quran_sura"),
                            image: #imageLiteral(resourceName: "page-empty-25"),
                            selectedImage: #imageLiteral(resourceName: "page-filled-25"))
    }
}
