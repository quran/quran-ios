//
//  Either.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum Either<S, U> {
    case First(S)
    case Second(U)
}
