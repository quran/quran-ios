//
//  AdvancedAudioOptionsSelectionTableViewCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-07.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

protocol AdvancedAudioOptionsSelectionTableViewCellDelegate: class {
    func advancedAudioOptionsSelectionTableViewCell(_ cell: AdvancedAudioOptionsSelectionTableViewCell, didSelectRow: Int, in component: Int)
}

class AdvancedAudioOptionsSelectionTableViewCell: ThemedTableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    weak var delegate: AdvancedAudioOptionsSelectionTableViewCellDelegate?

    @IBOutlet weak var picker: UIPickerView!

    var items: [[String]] = [] {
        didSet {
            if items.count != oldValue.count {
                picker.reloadAllComponents()
            } else {
                for (index, (newList, oldList)) in zip(items, oldValue).enumerated() where oldList != newList {
                    picker.reloadComponent(index)
                }
            }
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return items.count
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items[component].count
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel? = view as? UILabel
        if pickerLabel == nil {
            pickerLabel = ThemedLabel()
            pickerLabel?.font =  UIFont.systemFont(ofSize: items.count > 1 && component == 1 ? 17 : 15)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = items[component][row]
        return unwrap(pickerLabel)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.advancedAudioOptionsSelectionTableViewCell(self, didSelectRow: row, in: component)
    }
}
