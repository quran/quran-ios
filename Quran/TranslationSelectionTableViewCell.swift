//
//  TranslationSelectionTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationSelectionTableViewCell: TranslationTableViewCell {
    @IBOutlet weak var checkbox: UIImageView!

    func setSelection(_ selected: Bool) {
        let image: UIImage
        if selected {
            image = #imageLiteral(resourceName: "checkbox-selected").withRenderingMode(.alwaysTemplate)
        } else {
            image = #imageLiteral(resourceName: "checkbox-unselected").withRenderingMode(.alwaysOriginal)
        }
        checkbox.image = image
    }
}
