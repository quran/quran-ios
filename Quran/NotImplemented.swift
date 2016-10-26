//
//  NotImplemented.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

func unimplemented<T>() -> T {
    fatalError("Unimplemented")
}

func unimplemented() -> Never {
    fatalError("Unimplemented")
}
