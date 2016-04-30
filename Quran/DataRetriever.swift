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

struct AnyDataRetriever<Data> {

    let retrieveClosure: (Data -> Void) -> Void

    init<DataRetrieverType: DataRetriever where DataRetrieverType.Data == Data>(dataRetriever: DataRetrieverType) {
        retrieveClosure = dataRetriever.retrieve
    }

    func retrieve(onCompletion onCompletion: Data -> Void) {
        retrieveClosure(onCompletion)
    }
}

extension DataRetriever {
    func erasedType() -> AnyDataRetriever<Data> {
        return AnyDataRetriever(dataRetriever: self)
    }
}
