//
//  TranslationsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/22/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import GenericDataSources

class TranslationsViewController: BaseTableViewController, TranslationsDataSourceDelegate {

    private let dataSource: TranslationsDataSource

    private let interactor: AnyInteractor<Void, [TranslationFull]>
    private let localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>

    private var activityIndicator: UIActivityIndicatorView? {
        return navigationItem.leftBarButtonItem?.customView as? UIActivityIndicatorView
    }

    init(interactor: AnyInteractor<Void, [TranslationFull]>,
         localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>,
         dataSource: TranslationsDataSource) {
        self.interactor = interactor
        self.localTranslationsInteractor = localTranslationsInteractor
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
        dataSource.delegate = self
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

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.stopAnimating()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.ds_register(headerFooterClass: JuzTableViewHeaderFooterView.self)
        tableView.ds_register(cellNib: TranslationTableViewCell.self)
        tableView.ds_useDataSource(dataSource)

        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.addSubview(refreshControl)

        loadLocalData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator?.startAnimating()
        refreshData()
    }

    func refreshData() {
        interactor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.setItems(items: translations)
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self)
            .always { [weak self] in
                self?.refreshControl.endRefreshing()
                self?.activityIndicator?.stopAnimating()
        }
    }

    private func loadLocalData() {
        localTranslationsInteractor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.setItems(items: translations)
                self?.tableView.reloadData()
            }.catchToAlertView(viewController: self)
    }

    func translationsDataSource(_ dataSource: AbstractDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }
}
