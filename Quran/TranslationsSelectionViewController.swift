//
//  TranslationsSelectionViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationsSelectionViewController: TranslationsViewController<TranslationSelectionTableViewCell> {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("translationsSelectionTitle", comment: "")
        navigationItem.prompt = NSLocalizedString("translationsSelectionPrompt", comment: "")
        navigationItem.titleView = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))

        tableView.allowsSelection = true
        tableView.register(cell: TranslationSelectionTableViewCell.self)
    }

    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
