//
//  AlertViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/10/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit
import Utilities

public class AlertViewController: UIViewController {
    // MARK: Lifecycle

    public init(message: String) {
        self.message = message
        super.init(nibName: nil, bundle: .module)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    override public func viewDidLoad() {
        super.viewDidLoad()
        actions.isHidden = true

        messageLabel.text = message
        contentView.layer.cornerRadius = 4

        // drop shadow
        contentView.layer.shadowOpacity = 0.6
        contentView.layer.shadowRadius = 3
        contentView.layer.shadowOffset = .zero
        contentView.layer.shadowColor = UIColor.systemGray.cgColor
    }

    public func addAction(_ name: String, action: (() -> Void)? = nil) {
        loadViewIfNeeded()
        actions.isHidden = false
        let button = ActionButton(type: .system)
        button.set(name: name, action: { [weak self] in
            action?()
            self?.hide()
        })
        actions.addArrangedSubview(button)
    }

    public func show(autoHideAfter delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.hide()
        }
        show()
    }

    // MARK: Internal

    @IBOutlet var contentView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var actions: UIStackView!

    func show() {
        loadViewIfNeeded()
        contentView.alpha = 0
        rootViewController.addFullScreenChild(self)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.contentView.alpha = 1
        }, completion: nil)
    }

    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
            self.contentView.alpha = 0
        }, completion: { _ in
            self.rootViewController.removeChild(self)
        })
    }

    // MARK: Private

    private let message: String

    private var rootViewController: UIViewController {
        UIApplication.shared.delegate!.window!!.rootViewController!
    }
}

private class ActionButton: UIButton {
    // MARK: Internal

    func set(name: String, action: @escaping () -> Void) {
        self.action = action
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        setTitle(name, for: .normal)
    }

    // MARK: Private

    private var action: (() -> Void)?

    @objc
    private func tapped() {
        action?()
    }
}

class AlertView: UIView {
    @IBOutlet var blockingView: UIView!

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let local = blockingView.convert(point, from: self)
        if blockingView.hitTest(local, with: event) != nil {
            return super.hitTest(point, with: event)
        }
        return nil
    }
}
