//
//  TestingEntity.swift
//
//
//  Created by Mohamed Afifi on 2023-05-30.
//

import CoreData

public protocol TestingEntity<T> {
    associatedtype T: NSManagedObject
    var object: T { get }
}
