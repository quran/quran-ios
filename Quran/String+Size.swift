//
//  String+Size.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
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

extension String {

    func size(withFont font: UIFont, constrainedToWidth width: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let box = self.boundingRect(with: size,
                                    options: .usesLineFragmentOrigin,
                                    attributes: [NSFontAttributeName: font],
                                    context: nil)
        return CGSize(width: ceil(box.width), height: ceil(box.height))
    }
}

extension NSAttributedString {

    func stringSize(constrainedToWidth width: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let size = CGSize(width: width, height: .greatestFiniteMagnitude)
        let box = self.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        return CGSize(width: ceil(box.width), height: ceil(box.height))
    }
}
