//
//  TranslationsViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/22/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationsViewController: BaseTableViewController, TranslationsDataSourceDelegate {

    private let dataSource: TranslationsDataSource

    private let interactor: AnyInteractor<Void, [TranslationFull]>
    private let localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>

    private var activityIndicator: UIActivityIndicatorView? {
        return navigationItem.rightBarButtonItem?.customView as? UIActivityIndicatorView
    }

    init(interactor: AnyInteractor<Void, [TranslationFull]>,
         localTranslationsInteractor: AnyInteractor<Void, [TranslationFull]>,
         downloader: DownloadManager) {
        self.interactor = interactor
        self.localTranslationsInteractor = localTranslationsInteractor
        dataSource = TranslationsDataSource(downloader: downloader, headerReuseId: "header")
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        tableView.sectionHeaderHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70

        tableView.allowsSelection = false
        tableView.register(cell: TranslationTableViewCell.self)
        tableView.register(JuzTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
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
        _ = interactor.execute()
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
        _ = localTranslationsInteractor.execute()
            .then(on: .main) { [weak self] translations -> Void in
                self?.dataSource.setItems(items: translations)
                self?.tableView.reloadData()
        }
    }

    func translationsDataSource(_ dataSource: TranslationsDataSource, errorOccurred error: Error) {
        showErrorAlert(error: error)
    }
}
