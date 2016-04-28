//
//  DataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol DataRetriever {
    associatedtype Data

    func retrieve(onCompletion onCompletion: Data -> Void)
}
