//
//  AdvancedAudioOptionsSelectionTableViewCell.swift
//  AudioCards
//
//  Created by Afifi, Mohamed on 2018-04-07.
//  Copyright © 2018 Afifi, Mohamed. All rights reserved.
//

import UIKit

protocol AdvancedAudioOptionsSelectionTableViewCellDelegate: class {
    func advancedAudioOptionsSelectionTableViewCell(_ cell: AdvancedAudioOptionsSelectionTableViewCell, didSelectRow: Int, in component: Int)
}

class AdvancedAudioOptionsSelectionTableViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

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
            pickerLabel = UILabel()
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
