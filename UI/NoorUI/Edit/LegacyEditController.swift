//
//  EditController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/7/17.
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

@MainActor
public protocol EditControllerDelegate: AnyObject {
    func hasItemsToEdit() -> Bool
}

@MainActor
public class LegacyEditController {
    // MARK: Lifecycle

    public init(usesRightBarButton: Bool) {
        self.usesRightBarButton = usesRightBarButton
    }

    // MARK: Open

    open var tableView: UITableView?
    open weak var delegate: EditControllerDelegate?
    open weak var navigationItem: UINavigationItem?

    open var isEnabled: Bool = true

    open func configure(tableView: UITableView?, delegate: EditControllerDelegate?, navigationItem: UINavigationItem?) {
        self.tableView = tableView
        self.delegate = delegate
        self.navigationItem = navigationItem
    }

    open func endEditing(_ animated: Bool) {
        guard isEnabled else {
            return
        }

        tableView?.setEditing(false, animated: animated)
        updateEditBarItem(animated: animated)
    }

    open func onEditingStateChanged() {
        guard isEnabled else {
            return
        }

        updateEditBarItem(animated: true)
    }

    @objc
    open func onEditBarButtonTapped() {
        guard isEnabled else {
            return
        }

        tableView?.setEditing(true, animated: true)
        updateEditBarItem(animated: true)
    }

    @objc
    open func onDoneBarButtonTapped() {
        guard isEnabled else {
            return
        }

        tableView?.setEditing(false, animated: true)
        updateEditBarItem(animated: true)
    }

    open func onEditableItemsUpdated() {
        guard isEnabled else {
            return
        }

        if !(delegate?.hasItemsToEdit() ?? false) {
            tableView?.setEditing(false, animated: true)
        }

        updateEditBarItem(animated: true)
    }

    // MARK: Public

    public let usesRightBarButton: Bool

    // MARK: Private

    private func updateEditBarItem(animated: Bool) {
        let button: UIBarButtonItem?
        if !(delegate?.hasItemsToEdit() ?? false) {
            button = nil
        } else if tableView?.isEditing ?? false {
            button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDoneBarButtonTapped))
        } else {
            button = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(onEditBarButtonTapped))
        }
        if navigationItem?.rightBarButtonItem?.action != button?.action {
            navigationItem?.setRightBarButton(button, animated: animated)
        }
    }
}
