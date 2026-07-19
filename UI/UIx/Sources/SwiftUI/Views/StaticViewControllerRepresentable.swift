//
//  StaticViewControllerRepresentable.swift
//
//
//  Created by Mohamed Afifi on 2023-12-25.
//

import SwiftUI

public struct StaticViewControllerRepresentable: UIViewControllerRepresentable {
    // MARK: Lifecycle

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // MARK: Public

    public let viewController: UIViewController

    public func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}
