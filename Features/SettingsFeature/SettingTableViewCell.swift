//
//  SettingTableViewCell.swift
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

import Combine
import UIKit

class SettingTableViewCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: Self.style, reuseIdentifier: reuseIdentifier)
        textLabel?.textColor = .label
        imageView?.tintColor = .label
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    class var style: UITableViewCell.CellStyle {
        fatalError("Should be subclassed")
    }
}

class DefaultSettingTableViewCell: SettingTableViewCell {
    override class var style: UITableViewCell.CellStyle {
        .default
    }
}

class Value1SettingTableViewCell: SettingTableViewCell {
    // MARK: Internal

    override class var style: UITableViewCell.CellStyle {
        .value1
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellable?.cancel()
        cancellable = nil
    }

    func bindDetailsTo(_ detailsStream: AnyPublisher<String, Never>) {
        cancellable = detailsStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.detailTextLabel?.text = newValue
            }
    }

    // MARK: Private

    private var cancellable: AnyCancellable?
}
