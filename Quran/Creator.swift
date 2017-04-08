//
//  Creator.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
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

protocol Creator {
    associatedtype CreatedObject
    associatedtype Parameters

    func create(_ parameters: Parameters) -> CreatedObject
}

struct AnyCreator<CreatedObject, Parameters>: Creator {

    let createClosure: (Parameters) -> CreatedObject

    init(createClosure: @escaping (Parameters) -> CreatedObject) {
        self.createClosure = createClosure
    }

    init<CreatorObject: Creator>(creator: CreatorObject) where CreatorObject.CreatedObject == CreatedObject, CreatorObject.Parameters == Parameters {
        createClosure = creator.create
    }

    func create(_ parameters: Parameters) -> CreatedObject {
        return createClosure(parameters)
    }
}

extension Creator {

    func asAnyCreator() -> AnyCreator<CreatedObject, Parameters> {
        return AnyCreator(creator: self)
    }
}
