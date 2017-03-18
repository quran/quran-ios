//
//  TranslationsSelectionViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/18/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationsSelectionViewController: TranslationsViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissViewController))
    }

    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
