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

    func create() -> CreatedObject
}

struct AnyCreator<CreatedObject>: Creator {

    let createClosure: () -> CreatedObject

    init<CreatorObject: Creator>(creator: CreatorObject) where CreatorObject.CreatedObject == CreatedObject {
        createClosure = creator.create
    }

    func create() -> CreatedObject {
        return createClosure()
    }
}

extension Creator {

    func erasedType() -> AnyCreator<CreatedObject> {
        return AnyCreator(creator: self)
    }
}
