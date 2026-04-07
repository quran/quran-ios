//
//  UIViewController+Share.swift
//
//
//  Created by Mohamed Afifi on 2023-12-10.
//

import UIKit

extension UIViewController {
    func share(_ activityItems: [Any], completion: (() -> Void)? = nil) {
        let activityViewController = UIActivityViewController(
            activityItems: activityItems, applicationActivities: nil
        )
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            completion?()
        }

        let view = navigationController?.view ?? view
        let viewBound = view.map { CGRect(x: $0.bounds.midX, y: $0.bounds.midY, width: 0, height: 0) }
        activityViewController.modalPresentationStyle = .formSheet
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.sourceRect = viewBound ?? .zero
        present(activityViewController, animated: true)
    }
}
