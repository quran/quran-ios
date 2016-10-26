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
