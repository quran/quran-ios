//
//  ThemedTableViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/6/18.
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

class ThemedTableViewController: UITableViewController {

    open var kind: Theme.Kind = .background {
        didSet { themeDidChange() }
    }
    open var separatorKind: Theme.Kind = .separator {
        didSet { themeDidChange() }
    }

    override var modalPresentationStyle: UIModalPresentationStyle {
        didSet { themeDidChange() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        themeDidChange()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeDidChange()
    }

    @objc
    func themeDidChange() {
        tableView.backgroundColor = kind.color
        tableView.separatorColor = separatorKind.color
        if modalPresentationStyle == .popover {
            popoverPresentationController?.backgroundColor = Theme.Kind.popover.color
        }
    }
}
