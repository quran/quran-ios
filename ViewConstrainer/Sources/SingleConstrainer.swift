//
//  SingleConstrainer.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/21/17.
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
public class SingleConstrainer: ViewConstrainer {
    public let constraint: NSLayoutConstraint

    init(view: UIView, constraint: NSLayoutConstraint, chain: [NSLayoutConstraint]) {
        self.constraint = constraint
        super.init(view: view, chain: chain)
    }

    convenience init(constrainer: ViewConstrainer, group: GroupConstrainer) {
        let chain = constrainer.chain + group.chain
        self.init(view: constrainer.view, constraint: group.constraints[0], chain: chain)
    }
}
