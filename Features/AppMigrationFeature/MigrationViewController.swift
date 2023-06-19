//
//  MigrationViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import NVActivityIndicatorView
import UIKit

public class MigrationViewController: BaseViewController {
    // MARK: Lifecycle

    public init() {
        super.init(nibName: nil, bundle: .module)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.startAnimating()
    }

    public func setTitles(_ titles: Set<String>) {
        loadViewIfNeeded()
        textLabel.numberOfLines = 0
        textLabel.text = titles.map { l($0) }.joined(separator: "\n")
    }

    // MARK: Internal

    @IBOutlet var textLabel: UILabel!
    @IBOutlet var activityIndicator: NVActivityIndicatorView!
}
