//
//  String+Size.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
