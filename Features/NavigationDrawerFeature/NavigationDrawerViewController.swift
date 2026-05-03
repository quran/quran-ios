//
//  NavigationDrawerViewController.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import SwiftUI
import UIKit

/// Hosts the in-reading navigation drawer (Surah / Juz / Notes / Bookmarks tabs).
public final class NavigationDrawerViewController: UIViewController {
    // MARK: - Lifecycle

    init(viewModel: NavigationDrawerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = sideTransition
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let host = UIHostingController(rootView: NavigationDrawerView(viewModel: viewModel))
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Private

    private let viewModel: NavigationDrawerViewModel
    // Held strongly because the system retains it weakly.
    private let sideTransition = NavigationDrawerSideTransition()
}
