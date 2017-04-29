//
//  String+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/25/17.
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

extension String {

    public var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    public var pathExtension: String {
        return (self as NSString).pathExtension
    }
    public var stringByDeletingLastPathComponent: String {
        return (self as NSString).deletingLastPathComponent
    }
    public var stringByDeletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    public var pathComponents: [String] {
        return (self as NSString).pathComponents
    }

    public func stringByAppendingPath(_ path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }

    public func stringByAppendingExtension(_ pathExtension: String) -> String {
        return (self as NSString).appendingPathExtension(pathExtension) ?? (self + "." + pathExtension)
    }

}
