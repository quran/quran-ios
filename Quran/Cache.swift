//
//  Cache.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol Cache {

    func objectForKey(key: AnyObject) -> AnyObject?

    func setObject(obj: AnyObject, forKey key: AnyObject)

    func removeAllObjects()
}


extension NSCache: Cache { }
