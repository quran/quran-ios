//
//  DataRetriever.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
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

import Foundation

protocol DataRetriever {
    associatedtype Data

    func retrieve(onCompletion: @escaping (Data) -> Void)
}

struct AnyDataRetriever<Data> {

    let retrieveClosure: (@escaping (Data) -> Void) -> Void

    init<DataRetrieverType: DataRetriever>(dataRetriever: DataRetrieverType) where DataRetrieverType.Data == Data {
        retrieveClosure = dataRetriever.retrieve
    }

    func retrieve(onCompletion: @escaping (Data) -> Void) {
        retrieveClosure(onCompletion)
    }
}

extension DataRetriever {
    func erasedType() -> AnyDataRetriever<Data> {
        return AnyDataRetriever(dataRetriever: self)
    }
}
