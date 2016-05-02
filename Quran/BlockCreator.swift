//
//  BlockCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

struct BlockCreator<CreatedObject>: Creator {

    let creationClosure: () -> CreatedObject

    func create() -> CreatedObject {
        return creationClosure()
    }
}
