//
//  ViewControllersCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

struct ViewControllersCreator<CreatedObject: UIViewController>: Creator {
    func create() -> CreatedObject {
        return CreatedObject()
    }
}
