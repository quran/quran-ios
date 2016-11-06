//
//  Creator.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol Creator {
    associatedtype CreatedObject
    associatedtype Parameters

    func create(parameters: Parameters) -> CreatedObject
}

struct AnyCreator<CreatedObject, Parameters>: Creator {

    let createClosure: (Parameters) -> CreatedObject

    init(createClosure: @escaping (Parameters) -> CreatedObject) {
        self.createClosure = createClosure
    }

    init<CreatorObject: Creator>(creator: CreatorObject) where CreatorObject.CreatedObject == CreatedObject, CreatorObject.Parameters == Parameters {
        createClosure = creator.create
    }

    func create(parameters: Parameters) -> CreatedObject {
        return createClosure(parameters)
    }
}

extension Creator {

    func erasedType() -> AnyCreator<CreatedObject, Parameters> {
        return AnyCreator(creator: self)
    }
}
