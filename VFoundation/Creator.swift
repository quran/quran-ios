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

public protocol Creator {
    associatedtype Parameters
    associatedtype CreatedObject

    func create(_ parameters: Parameters) -> CreatedObject
}

public struct AnyCreator<Parameters, CreatedObject>: Creator {

    private let createClosure: (Parameters) -> CreatedObject

    public init(createClosure: @escaping (Parameters) -> CreatedObject) {
        self.createClosure = createClosure
    }

    public init<CreatorObject: Creator>(creator: CreatorObject)
        where CreatorObject.CreatedObject == CreatedObject, CreatorObject.Parameters == Parameters {
        createClosure = creator.create
    }

    public func create(_ parameters: Parameters) -> CreatedObject {
        return createClosure(parameters)
    }
}

extension Creator {

    public func asAnyCreator() -> AnyCreator<Parameters, CreatedObject> {
        return AnyCreator(creator: self)
    }
}

public typealias AnyGetCreator<CreatedObject> = AnyCreator<Void, CreatedObject>
