//
//  TranslationsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/22/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationsViewController: BaseTableViewController {

    private let dataSource = TranslationsDataSource(reuseIdentifier: TranslationTableViewCell.reuseId)

    private let interactor: AnyInteractor<Void, [Translation]>

    init(interactor: AnyInteractor<Void, [Translation]>) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = ""
        navigationItem.titleView = UIImageView(image: UIImage(named: "logo-22")?.withRenderingMode(.alwaysTemplate))

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.register(cell: TranslationTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshData()
    }

    func refreshData() {
        refreshControl.beginRefreshing()
        _ = interactor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.items = translations
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self).always { [weak self] in
                self?.refreshControl.endRefreshing()
        }
    }
}
