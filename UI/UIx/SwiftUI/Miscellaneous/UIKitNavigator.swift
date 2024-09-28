//
//  UIKitNavigator.swift
//
//
//  Created by Mohamed Afifi on 2024-09-27.
//

import SwiftUI

public final class UIKitNavigator {
    public weak var viewController: UIViewController?
    var navigationController: UINavigationController? {
        if let navController = viewController as? UINavigationController {
            navController
        } else {
            viewController?.navigationController
        }
    }
}

struct UINavigatorKey: EnvironmentKey {
    static var defaultValue: UIKitNavigator? = nil
}

extension EnvironmentValues {
    public var uikitNavigator: UIKitNavigator? {
        get { self[UINavigatorKey.self] }
        set { self[UINavigatorKey.self] = newValue }
    }
}

extension View {
    public func enableUIKitNavigator() -> some View {
        modifier(EnableUIKitNavigator())
    }
}

private struct EnableUIKitNavigator: ViewModifier {
    @State var navigator = UIKitNavigator()

    func body(content: Content) -> some View {
        content
            .background(UIViewControllerReader(navigator: navigator))
            .environment(\.uikitNavigator, navigator)
    }
}

private struct UIViewControllerReader: UIViewControllerRepresentable {
    let navigator: UIKitNavigator

    func makeUIViewController(context: Context) -> UIViewController {
        ViewControllerReader(navigator: navigator)
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
    }

    private class ViewControllerReader: UIViewController {
        let navigator: UIKitNavigator

        init(navigator: UIKitNavigator) {
            self.navigator = navigator
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            navigator.viewController = parent
        }
    }
}
