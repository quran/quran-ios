//
//  UIViewControllerReader.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-28.
//

import SwiftUI

public struct UIViewControllerReader: UIViewControllerRepresentable {
    @Binding private var viewController: UIViewController?
    public init(viewController: Binding<UIViewController?>) {
        _viewController = viewController
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        let dummy = UIViewController()
        DispatchQueue.main.async {
            viewController = dummy
        }
        return dummy
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
