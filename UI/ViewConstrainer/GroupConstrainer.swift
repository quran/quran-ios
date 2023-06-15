//
//  GroupConstrainer.swift
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

import UIKit

public class GroupConstrainer: ViewConstrainer {
    public let constraints: [NSLayoutConstraint]

    init(view: UIView, constraints: [NSLayoutConstraint], chain: [NSLayoutConstraint]) {
        self.constraints = constraints
        super.init(view: view, chain: chain)
    }

    convenience init(constrainer: ViewConstrainer, group: [SingleConstrainer]) {
        let chain = constrainer.chain + group.flatMap(\.chain)
        self.init(view: constrainer.view, constraints: group.map(\.constraint), chain: chain)
    }

    convenience init(constrainer: ViewConstrainer, group: [GroupConstrainer]) {
        let chain = constrainer.chain + group.flatMap(\.chain)
        self.init(view: constrainer.view, constraints: group.flatMap(\.constraints), chain: chain)
    }
}
